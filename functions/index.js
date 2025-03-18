const functions = require("firebase-functions");
const functionsV2 = require("firebase-functions/v2");
const admin = require("firebase-admin");
const { DateTime } = require("luxon");

admin.initializeApp();

// ================ SUBSCRIPTION MANAGEMENT FUNCTIONS ================

// Scheduled function to check for subscriptions that need renewal
exports.checkSubscriptionRenewals = functionsV2.scheduler
  .onSchedule({
    schedule: "every 24 hours",
    timeZone: "Asia/Kolkata", // Add your preferred timezone
  }, async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    try {
      // Get all active subscriptions
      const subscriptionsQuery = await db.collection("users")
        .where("isActive", "==", true)
        .where("autoRenew", "==", true)
        .get();

      let renewalCount = 0;

      for (const doc of subscriptionsQuery.docs) {
        const userData = doc.data();

        // Check if subscription is due for renewal (within 24 hours)
        if (userData.subscriptionEndDate && userData.subscriptionEndDate.toDate() <= new Date(Date.now() + 24 * 60 * 60 * 1000)) {
          await processRenewal(doc.id, userData);
          renewalCount++;
        }

        // Check if trial period is ending
        if (userData.inTrial && userData.trialEndDate && userData.trialEndDate.toDate() <= new Date(Date.now() + 24 * 60 * 60 * 1000)) {
          await processTrialEnd(doc.id, userData);
        }
      }

      functions.logger.info(`Processed ${renewalCount} subscription renewals`);
      return null;
    } catch (error) {
      functions.logger.error("Error checking subscription renewals:", error);
      return null;
    }
  });

// Function to process a subscription renewal
async function processRenewal(userId, userData) {
  const db = admin.firestore();

  try {
    const subscriptionType = userData.subscriptionType || "monthly";
    const now = new Date();
    let newEndDate;

    // Calculate new end date based on subscription type
    switch (subscriptionType) {
      case "monthly":
        newEndDate = new Date(now.getFullYear(), now.getMonth() + 1, now.getDate());
        break;
      case "quarterly":
        newEndDate = new Date(now.getFullYear(), now.getMonth() + 3, now.getDate());
        break;
      case "annual":
        newEndDate = new Date(now.getFullYear() + 1, now.getMonth(), now.getDate());
        break;
      default:
        newEndDate = new Date(now.getFullYear(), now.getMonth() + 1, now.getDate());
    }

    // Update subscription end date
    await db.collection("users").doc(userId).update({
      subscriptionEndDate: admin.firestore.Timestamp.fromDate(newEndDate),
      lastRenewalDate: admin.firestore.Timestamp.now()
    });

    // Log the renewal
    await db.collection("subscription_events").add({
      userId: userId,
      event: "renewal",
      subscriptionType: subscriptionType,
      amount: getSubscriptionAmount(subscriptionType),
      timestamp: admin.firestore.Timestamp.now()
    });

    functions.logger.info(`Renewed subscription for user ${userId}`);
  } catch (error) {
    functions.logger.error(`Error processing renewal for user ${userId}:`, error);
  }
}

// Function to process the end of a trial period
async function processTrialEnd(userId, userData) {
  const db = admin.firestore();

  try {
    const subscriptionType = userData.subscriptionType || "monthly";
    const fullAmount = userData.nextBillingAmount || getSubscriptionAmount(subscriptionType);

    // Mark trial as ended
    await db.collection("users").doc(userId).update({
      inTrial: false,
      lastPaymentDate: admin.firestore.Timestamp.now(),
      lastPaymentAmount: fullAmount
    });

    // Log the trial end
    await db.collection("subscription_events").add({
      userId: userId,
      event: "trial_ended",
      subscriptionType: subscriptionType,
      fullAmount: fullAmount,
      timestamp: admin.firestore.Timestamp.now()
    });

    functions.logger.info(`Processed trial end for user ${userId}`);
  } catch (error) {
    functions.logger.error(`Error processing trial end for user ${userId}:`, error);
  }
}

// Helper function to get subscription amount based on type
function getSubscriptionAmount(subscriptionType) {
  switch (subscriptionType) {
    case "monthly":
      return 99;
    case "quarterly":
      return 299;
    case "annual":
      return 499;
    case "perTemplate":
      return 19;
    default:
      return 99;
  }
}

// Function triggered when a payment is recorded
exports.onPaymentReceived = functionsV2.firestore
  .onDocumentCreated("transactions/{transactionId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return null;

    const payment = snapshot.data();
    const userId = payment.userId;

    if (!userId || payment.status !== "success") {
      return null;
    }

    try {
      const db = admin.firestore();
      const userRef = db.collection("users").doc(userId);

      // If this is a template purchase, add points
      if (payment.planType === "Per Template") {
        await userRef.update({
          points: admin.firestore.FieldValue.increment(20)
        });

        functions.logger.info(`Added 20 points to user ${userId}`);
        return null;
      }

      // If this is a subscription payment, update subscription details
      if (payment.isSubscription) {
        const now = new Date();
        let endDate;

        // Calculate subscription end date
        switch (payment.recurringType) {
          case "monthly":
            endDate = new Date(now.getFullYear(), now.getMonth() + 1, now.getDate());
            break;
          case "quarterly":
            if (payment.trialDays > 0) {
              // First set trial end date
              const trialEndDate = new Date(now.getTime() + payment.trialDays * 24 * 60 * 60 * 1000);
              endDate = new Date(trialEndDate.getFullYear(), trialEndDate.getMonth() + 3, trialEndDate.getDate());
            } else {
              endDate = new Date(now.getFullYear(), now.getMonth() + 3, now.getDate());
            }
            break;
          case "annual":
            endDate = new Date(now.getFullYear() + 1, now.getMonth(), now.getDate());
            break;
          default:
            endDate = new Date(now.getFullYear(), now.getMonth() + 1, now.getDate());
        }

        const subscriptionData = {
          activePlan: payment.planType,
          subscriptionType: payment.recurringType,
          subscriptionEndDate: admin.firestore.Timestamp.fromDate(endDate),
          isActive: true,
          autoRenew: true,
          lastPaymentDate: admin.firestore.Timestamp.now(),
          lastPaymentAmount: payment.amount
        };

        // Handle trial periods
        if (payment.trialDays > 0) {
          const trialEndDate = new Date(now.getTime() + payment.trialDays * 24 * 60 * 60 * 1000);
          subscriptionData.inTrial = true;
          subscriptionData.trialEndDate = admin.firestore.Timestamp.fromDate(trialEndDate);
          subscriptionData.nextBillingDate = admin.firestore.Timestamp.fromDate(trialEndDate);
          subscriptionData.nextBillingAmount = payment.fullAmount || "290";
        } else {
          subscriptionData.inTrial = false;
        }

        await userRef.update(subscriptionData);

        functions.logger.info(`Updated subscription for user ${userId}`);
      }

      return null;
    } catch (error) {
      functions.logger.error(`Error processing payment for user ${userId}:`, error);
      return null;
    }
  });

// Function to handle subscription cancellations
exports.onSubscriptionCancel = functionsV2.firestore
  .onDocumentCreated("subscription_events/{eventId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return null;

    const event_data = snapshot.data();

    if (event_data.event !== "cancel") {
      return null;
    }

    const userId = event_data.userId;

    try {
      const db = admin.firestore();
      await db.collection("users").doc(userId).update({
        autoRenew: false
      });

      functions.logger.info(`Marked subscription as cancelled for user ${userId}`);
      return null;
    } catch (error) {
      functions.logger.error(`Error processing subscription cancellation for user ${userId}:`, error);
      return null;
    }
  });

// ================ NOTIFICATION FUNCTIONS ================

// QOTD Notification
exports.sendDailyQOTDNotification = functionsV2.scheduler
  .onSchedule({
    schedule: "0 9 * * *", // Runs every day at 9 AM
    timeZone: "Asia/Kolkata", // Set to your time zone
  }, async (context) => {
    try {
      const today = DateTime.now().setZone("Asia/Kolkata").toFormat("dd-MM-yyyy");

      const qotdRef = admin.firestore().collection("qotd").doc(today);
      const doc = await qotdRef.get();

      if (!doc.exists) {
        console.log("No QOTD found for today.");
        return;
      }

      const qotdData = doc.data();
      let imageUrl = qotdData.imageURL;
      const quoteText = qotdData.quote;

      // Fix image URL format if needed
      if (imageUrl && !imageUrl.startsWith("https://")) {
        console.log("Fixing image URL format");
        imageUrl = imageUrl.replace("https:/", "https://");
      }

      console.log("Using image URL:", imageUrl);

      const payload = {
        notification: {
          title: "Quote of the Day",
          body: quoteText,
          image: imageUrl
        },
        android: {
          notification: {
            image: imageUrl,
            priority: "high",
            visibility: "public",
            channelId: "high_importance_channel"
          }
        },
        apns: {
          payload: {
            aps: {
              mutableContent: 1,
              contentAvailable: true
            }
          },
          fcmOptions: {
            image: imageUrl
          }
        },
        topic: "qotd",
      };

      await admin.messaging().send(payload);
      console.log("QOTD Notification Sent:", quoteText);
    } catch (error) {
      console.error("Error sending QOTD notification:", error);
    }
  });

// TOTD Morning Notification (7:00 AM)
exports.sendMorningTOTDNotification = functionsV2.scheduler
  .onSchedule({
    schedule: "0 7 * * *", // Runs every day at 7 AM
    timeZone: "Asia/Kolkata",
  }, async (context) => {
    await sendTOTDNotification("morning", "Morning Thought");
  });

// TOTD Afternoon Notification (1:00 PM)
exports.sendAfternoonTOTDNotification = functionsV2.scheduler
  .onSchedule({
    schedule: "0 13 * * *", // Runs every day at 1 PM
    timeZone: "Asia/Kolkata",
  }, async (context) => {
    await sendTOTDNotification("afternoon", "Afternoon Thought");
  });

// TOTD Evening Notification (6:00 PM)
exports.sendEveningTOTDNotification = functionsV2.scheduler
  .onSchedule({
    schedule: "0 18 * * *", // Runs every day at 6 PM
    timeZone: "Asia/Kolkata",
  }, async (context) => {
    await sendTOTDNotification("evening", "Evening Thought");
  });

// Helper function to handle TOTD notifications
async function sendTOTDNotification(timeOfDay, notificationTitle) {
  try {
    // Get the specified timeOfDay document (morning, afternoon, or evening)
    const totdRef = admin.firestore().collection("totd").doc(timeOfDay);
    const totdDoc = await totdRef.get();

    if (!totdDoc.exists) {
      console.log(`No TOTD found for ${timeOfDay}.`);
      return;
    }

    const totdData = totdDoc.data();

    // Check if there are posts available
    const posts = Object.keys(totdData)
      .filter(key => key.startsWith('post') && totdData[key].imageUrl);

    if (posts.length === 0) {
      console.log(`No valid posts found for ${timeOfDay} TOTD.`);
      return;
    }

    // Get current date for logging
    const today = new Date().toLocaleDateString('en-IN', { timeZone: 'Asia/Kolkata' });

    // Randomly select one post from the available posts
    const randomPostKey = posts[Math.floor(Math.random() * posts.length)];
    const selectedPost = totdData[randomPostKey];

    // Extract the data from the selected post
    let imageUrl = selectedPost.imageUrl;
    const title = selectedPost.title || `${timeOfDay.charAt(0).toUpperCase() + timeOfDay.slice(1)} Thought of the Day`;

    // Fix image URL format if needed
    if (imageUrl && !imageUrl.startsWith("https://")) {
      console.log(`Fixing image URL format for ${timeOfDay} TOTD`);
      imageUrl = imageUrl.replace("https:/", "https://");
    }

    console.log(`Using image URL for ${timeOfDay} TOTD:`, imageUrl);

    // Create notification payload with platform-specific configurations
    const payload = {
      notification: {
        title: notificationTitle,
        body: title,
        image: imageUrl
      },
      data: {
        type: "totd",
        timeOfDay: timeOfDay,
        postId: randomPostKey,
        createdAt: selectedPost.createdAt ? selectedPost.createdAt.toDate().toISOString() : new Date().toISOString()
      },
      android: {
        notification: {
          image: imageUrl,
          priority: "high",
          visibility: "public",
          channelId: "high_importance_channel"
        }
      },
      apns: {
        payload: {
          aps: {
            mutableContent: 1,
            contentAvailable: true
          }
        },
        fcmOptions: {
          image: imageUrl
        }
      },
      topic: "totd",
    };

    await admin.messaging().send(payload);
    console.log(`${timeOfDay.toUpperCase()} TOTD Notification Sent on ${today}: "${title}" with image: ${imageUrl}`);

    // Record notification sent in analytics collection if needed
    await admin.firestore().collection("analytics").doc("notifications").collection("totd").add({
      timeOfDay: timeOfDay,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      postId: randomPostKey,
      image: imageUrl,
      title: title
    });

  } catch (error) {
    console.error(`Error sending ${timeOfDay} TOTD notification:`, error);

    // Log error to separate collection for monitoring
    await admin.firestore().collection("errors").add({
      feature: "totd_notification",
      timeOfDay: timeOfDay,
      error: error.message,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
  }
}

// Festival Notifications - Checks daily at 3 PM and sends notification for upcoming festivals
exports.checkAndSendFestivalNotifications = functionsV2.scheduler
  .onSchedule({
    schedule: "0 15 * * *", // Runs every day at 3 PM Indian time
    timeZone: "Asia/Kolkata",
  }, async (context) => {
    await checkUpcomingFestivals();
  });

async function checkUpcomingFestivals() {
  try {
    // Get current date in Indian timezone
    const now = new Date();
    const todayIndia = admin.firestore.Timestamp.fromDate(new Date(
      now.toLocaleString('en-US', { timeZone: 'Asia/Kolkata' })
    ));
    
    console.log(`Checking festivals: Current date in India: ${todayIndia.toDate().toLocaleDateString()}`);

    // Get all festivals from Firestore
    const festivalsSnapshot = await admin.firestore().collection("festivals").get();
    
    if (festivalsSnapshot.empty) {
      console.log("No festivals found in the database.");
      return;
    }

    // Check each festival
    for (const festivalDoc of festivalsSnapshot.docs) {
      const festival = festivalDoc.data();
      const festivalDate = festival.festivalDate.toDate();
      const showDaysBefore = festival.showDaysBefore || 7; // Default to 7 days if not specified
      
      // Calculate notification start date (festival date - showDaysBefore)
      const notificationStartDate = new Date(festivalDate);
      notificationStartDate.setDate(notificationStartDate.getDate() - showDaysBefore);
      
      // Convert to timestamp for comparison
      const notificationStartTimestamp = admin.firestore.Timestamp.fromDate(notificationStartDate);
      
      // Calculate days remaining until festival
      const diffTime = festivalDate.getTime() - todayIndia.toDate().getTime();
      const daysRemaining = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
      
      console.log(`Festival: ${festival.name}, Date: ${festivalDate.toLocaleDateString()}, Days remaining: ${daysRemaining}`);
      
      // Check if today is within the notification period and festival hasn't passed yet
      if (todayIndia.toDate() >= notificationStartDate && daysRemaining >= 0) {
        console.log(`Festival ${festival.name} is upcoming in ${daysRemaining} days. Sending notification.`);
        
        // Send notification for this festival
        await sendFestivalNotification(festival, festivalDoc.id, daysRemaining);
      }
    }
    
    console.log("Festival check completed.");
  } catch (error) {
    console.error("Error checking upcoming festivals:", error);
    
    // Log error to separate collection for monitoring
    await admin.firestore().collection("errors").add({
      feature: "festival_notification",
      error: error.message,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
  }
}

async function sendFestivalNotification(festival, festivalId, daysRemaining) {
  try {
    const templates = festival.templates || [];
    
    if (templates.length === 0) {
      console.log(`No templates found for festival: ${festival.name}`);
      return;
    }
    
    // Select a random template from available non-paid ones
    const availableTemplates = templates.filter(template => !template.isPaid);
    
    if (availableTemplates.length === 0) {
      console.log(`No free templates available for festival: ${festival.name}`);
      return;
    }
    
    const randomTemplate = availableTemplates[Math.floor(Math.random() * availableTemplates.length)];
    
    let imageUrl = randomTemplate.imageURL;
    
    // Fix image URL format if needed
    if (imageUrl && !imageUrl.startsWith("https://")) {
      console.log(`Fixing image URL format for festival: ${festival.name}`);
      imageUrl = imageUrl.replace("https:/", "https://");
    }
    
    console.log(`Using image URL for ${festival.name}:`, imageUrl);
    
    // Create notification message based on days remaining
    let notificationTitle = `${festival.name} is coming!`;
    let notificationBody = "";
    
    if (daysRemaining === 0) {
      notificationBody = `Happy ${festival.name}! Celebrate with friends and family today.`;
    } else if (daysRemaining === 1) {
      notificationBody = `${festival.name} is tomorrow! Get ready to celebrate.`;
    } else {
      notificationBody = `Only ${daysRemaining} days left until ${festival.name}!`;
    }
    
    // Create notification payload with platform-specific configurations
    const payload = {
      notification: {
        title: notificationTitle,
        body: notificationBody,
        image: imageUrl
      },
      data: {
        type: "festivals",
        festivalId: festivalId,
        festivalName: festival.name,
        daysRemaining: daysRemaining.toString(),
        templateId: randomTemplate.id || "",
        festivalDate: festival.festivalDate.toDate().toISOString()
      },
      android: {
        notification: {
          image: imageUrl,
          priority: "high",
          visibility: "public",
          channelId: "high_importance_channel"
        }
      },
      apns: {
        payload: {
          aps: {
            mutableContent: 1,
            contentAvailable: true
          }
        },
        fcmOptions: {
          image: imageUrl
        }
      },
      topic: "festivals",
    };
    
    await admin.messaging().send(payload);
    console.log(`Festival Notification Sent for ${festival.name}: "${notificationBody}" with image: ${imageUrl}`);
    
    // Record notification sent in analytics collection
    await admin.firestore().collection("analytics").doc("notifications").collection("festivals").add({
      festivalId: festivalId,
      festivalName: festival.name,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      daysRemaining: daysRemaining,
      templateId: randomTemplate.id || "",
      imageUrl: imageUrl,
      message: notificationBody
    });
    
  } catch (error) {
    console.error(`Error sending notification for festival ${festival.name}:`, error);
    
    // Log error to separate collection for monitoring
    await admin.firestore().collection("errors").add({
      feature: "festival_notification",
      festivalName: festival.name,
      error: error.message,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
  }
}