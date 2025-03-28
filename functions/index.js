const functions = require("firebase-functions");
const functionsV2 = require("firebase-functions/v2");
const admin = require("firebase-admin");
const { DateTime } = require("luxon");
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');

admin.initializeApp();

// ================ SUBSCRIPTION MANAGEMENT FUNCTIONS ================

const db = admin.firestore();

exports.migrateUserSubscriptionFields = functions.https.onRequest(async (req, res) => {
  try {
    const usersSnapshot = await admin.firestore().collection('users').get();
    const batch = admin.firestore().batch();

    usersSnapshot.forEach(doc => {
      const userData = doc.data();

      // Set subscription fields based on current user data
      batch.update(doc.ref, {
        subscriptionStatus: userData.isSubscribed ? "active" : "none",
        currentPlan: userData.isSubscribed ? "Monthly Plan" : "free", // Assumption - change as needed
        points: userData.rewardPoints || 0,
        subscriptionEndDate: null, // Will be populated when they subscribe
        isTrial: false,
        recurringType: null,
        dailyTemplateLimit: userData.isSubscribed ? 10 : 0, // Assumption
        availableTemplates: 0,
        canEdit: userData.isSubscribed
      });
    });

    await batch.commit();
    res.status(200).send(`Migrated ${usersSnapshot.size} users`);
  } catch (error) {
    console.error('Migration error:', error);
    res.status(500).send(`Error: ${error.message}`);
  }
});

// Webhook endpoint to receive payment status updates from your payment gateway
exports.upiWebhook = functions.https.onRequest(async (req, res) => {
  try {
    // Verify the request source using a secret key or signature
    // This is important for security
    const apiKey = req.headers['x-api-key'];
    if (apiKey !== functions.config().payment?.webhook_secret) {
      res.status(401).send('Unauthorized');
      return;
    }

    const { transactionId, status, referenceId } = req.body;

    // Validate required fields
    if (!transactionId || !status) {
      res.status(400).send('Invalid request payload');
      return;
    }

    // Check if the transaction exists
    const paymentRef = db.collection('payments').doc(transactionId);
    const paymentDoc = await paymentRef.get();

    if (!paymentDoc.exists) {
      res.status(404).send('Transaction not found');
      return;
    }

    const paymentData = paymentDoc.data();

    // Update payment status
    await paymentRef.update({
      status: status,
      referenceId: referenceId || null,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      statusDetails: req.body
    });

    // If payment is successful, update user subscription
    if (status === 'success') {
      const userId = paymentData.userId;

      // Get user document
      const userRef = db.collection('users').doc(userId);
      const userDoc = await userRef.get();

      if (userDoc.exists) {
        // Update user's subscription status
        await userRef.update({
          subscriptionStatus: 'active',
          lastPaymentDate: admin.firestore.FieldValue.serverTimestamp(),
          paymentVerified: true
        });

        // If it's a subscription, check if we need to add points
        if (paymentData.planType === 'Per Template') {
          // Add points to user balance
          const currentPoints = userDoc.data().points || 0;
          await userRef.update({
            points: currentPoints + 20 // 20 points for Per Template plan
          });
        }
      }
    }

    res.status(200).send({ success: true });
  } catch (error) {
    console.error('Error in UPI webhook:', error);
    res.status(500).send({ error: error.message });
  }
});

// Scheduled function to check for trial period expiration and handle subscription renewals
// Using Firebase Functions v2 for scheduled functions
exports.manageSubscriptions = functionsV2.scheduler
  .onSchedule({
  schedule: 'every 24 hours',
  timeZone: 'Asia/Kolkata', // Use the appropriate timezone for your region
}, async (context) => {
  const now = admin.firestore.Timestamp.now();

  try {
    // Find users with active subscriptions that are in trial
    const trialUsersQuery = await db.collection('users')
      .where('subscriptionStatus', '==', 'active')
      .where('isTrial', '==', true)
      .where('subscriptionEndDate', '<=', now)
      .get();

    // Process trial expirations
    const trialExpireBatch = db.batch();
    trialUsersQuery.forEach(doc => {
      const userData = doc.data();

      // If it was a trial, create a new payment record for the full amount
      if (userData.transactionId) {
        const paymentRef = db.collection('payments').doc(); // New payment doc
        trialExpireBatch.set(paymentRef, {
          userId: doc.id,
          userName: userData.name || userData.userName,
          planType: userData.currentPlan,
          amount: userData.fullAmount || userData.amount,
          transactionId: paymentRef.id,
          paymentNote: `Renewal after trial for ${userData.currentPlan}`,
          timestamp: now,
          status: 'pending',
          paymentMethod: 'automatic-renewal',
          isSubscription: true,
          recurringType: userData.recurringType,
          startDate: now,
          endDate: calculateEndDate(now, userData.recurringType),
          isTrial: false,
        });

        // Update user record
        trialExpireBatch.update(doc.ref, {
          isTrial: false,
          subscriptionStatus: 'pending_renewal',
          paymentDue: true,
          paymentDueDate: now,
          paymentAmount: userData.fullAmount || userData.amount,
          transactionId: paymentRef.id
        });
      }
    });

    // Commit all trial expiration updates
    if (trialUsersQuery.size > 0) {
      await trialExpireBatch.commit();
      console.log(`Processed ${trialUsersQuery.size} trial expirations`);
    }

    // Find subscriptions that need renewal
    const renewalQuery = await db.collection('users')
      .where('subscriptionStatus', '==', 'active')
      .where('isTrial', '==', false)
      .where('subscriptionEndDate', '<=', now)
      .get();

    // Process renewals
    const renewalBatch = db.batch();
    renewalQuery.forEach(doc => {
      const userData = doc.data();

      // Create a new payment record for renewal
      const paymentRef = db.collection('payments').doc(); // New payment doc
      renewalBatch.set(paymentRef, {
        userId: doc.id,
        userName: userData.name || userData.userName,
        planType: userData.currentPlan,
        amount: userData.amount,
        transactionId: paymentRef.id,
        paymentNote: `Renewal for ${userData.currentPlan}`,
        timestamp: now,
        status: 'pending',
        paymentMethod: 'automatic-renewal',
        isSubscription: true,
        recurringType: userData.recurringType,
        startDate: now,
        endDate: calculateEndDate(now, userData.recurringType),
        isTrial: false,
      });

      // Update user record
      renewalBatch.update(doc.ref, {
        subscriptionStatus: 'pending_renewal',
        paymentDue: true,
        paymentDueDate: now,
        paymentAmount: userData.amount,
        transactionId: paymentRef.id
      });
    });

    // Commit all renewal updates
    if (renewalQuery.size > 0) {
      await renewalBatch.commit();
      console.log(`Processed ${renewalQuery.size} subscription renewals`);
    }

    return null;
  } catch (error) {
    console.error('Error managing subscriptions:', error);
    return null;
  }
});

// Helper function to calculate subscription end date
function calculateEndDate(startDate, recurringType) {
  const start = startDate.toDate();
  let end;

  switch (recurringType) {
    case 'monthly':
      end = new Date(start);
      end.setMonth(end.getMonth() + 1);
      break;
    case 'quarterly':
      end = new Date(start);
      end.setMonth(end.getMonth() + 3);
      break;
    case 'annual':
      end = new Date(start);
      end.setFullYear(end.getFullYear() + 1);
      break;
    default:
      end = new Date(start);
      end.setMonth(end.getMonth() + 1); // Default to monthly
  }

  return admin.firestore.Timestamp.fromDate(end);
}

// Upgrade user from free to pro when payment is successful

exports.onPaymentStatusChange = onDocumentUpdated('payments/{paymentId}', (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

    // Only proceed if status changed from pending to success
    if (before.status !== 'success' && after.status === 'success') {
      const userId = after.userId;

      return db.collection('users')
        .doc(userId)
        .get()
        .then(userSnapshot => {
          if (!userSnapshot.exists) {
            console.error(`User ${userId} not found for successful payment ${context.params.paymentId}`);
            return null;
          }

          const userData = userSnapshot.data();

          // Determine plan benefits based on plan type
          let updateData = {
            subscriptionStatus: 'active',
            lastSuccessfulPayment: admin.firestore.FieldValue.serverTimestamp(),
            currentPlan: after.planType,
          };

          // If it's a one-time purchase (Per Template)
          if (after.planType === 'Per Template') {
            updateData.points = (userData.points || 0) + 20;
            updateData.availableTemplates = (userData.availableTemplates || 0) + 1;
          }
          // If it's a subscription plan
          else if (after.isSubscription) {
            const now = admin.firestore.Timestamp.now();
            updateData.subscriptionStartDate = after.startDate || now;
            updateData.subscriptionEndDate = after.endDate || calculateEndDate(now, after.recurringType);
            updateData.isTrial = after.isTrial || false;
            updateData.recurringType = after.recurringType;

            // Set template limits based on plan
            if (after.planType === 'Monthly Plan') {
              updateData.dailyTemplateLimit = 10;
              updateData.canEdit = true;
            } else if (after.planType === 'Quarterly Plan' || after.planType === 'Annual Plan') {
              updateData.dailyTemplateLimit = -1; // Unlimited
              updateData.canEdit = true;
            }
          }

          // Update user document
          return db.collection('users')
            .doc(userId)
            .update(updateData)
            .then(() => {
              console.log(`Successfully processed payment ${context.params.paymentId} for user ${userId}`);
              return null;
            });
        })
        .catch(error => {
          console.error(`Error processing payment success for ${context.params.paymentId}:`, error);
          return null;
        });
    }

    return null;
  });

// Function to handle UPI callback or simulate payment verification (for testing)
exports.verifyUpiPayment = functions.https.onCall(async (data, context) => {
  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to verify payments'
    );
  }

  const { transactionId } = data;

  if (!transactionId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Transaction ID is required'
    );
  }

  try {
    // Check if transaction exists
    const paymentRef = db.collection('payments').doc(transactionId);
    const paymentDoc = await paymentRef.get();

    if (!paymentDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Transaction not found'
      );
    }

    const paymentData = paymentDoc.data();

    // Security check: Only allow users to verify their own payments
    if (paymentData.userId !== context.auth.uid) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Users can only verify their own payments'
      );
    }

    // For testing/demo purposes - In production, this would connect to your payment gateway API
    // This function allows manual verification in the app for testing
    await paymentRef.update({
      status: 'success',
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      manualVerification: true
    });

    return { success: true, message: 'Payment verified successfully' };
  } catch (error) {
    console.error('Error verifying payment:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Function to cancel a user's subscription
exports.cancelSubscription = functions.https.onCall(async (data, context) => {
  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to cancel subscription'
    );
  }

  try {
    const userId = context.auth.uid;
    const userRef = db.collection('users').doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const userData = userDoc.data();

    // Check if user has an active subscription
    if (userData.subscriptionStatus !== 'active') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'No active subscription to cancel'
      );
    }

    // Update user document
    await userRef.update({
      subscriptionStatus: 'cancelled',
      cancellationDate: admin.firestore.FieldValue.serverTimestamp(),
      // The subscription remains active until the end date
      willExpireOn: userData.subscriptionEndDate
    });

    // Log the cancellation in a separate collection for record-keeping
    await db.collection('cancellations').add({
      userId: userId,
      userName: userData.name || userData.userName,
      planType: userData.currentPlan,
      cancellationDate: admin.firestore.FieldValue.serverTimestamp(),
      subscriptionEndDate: userData.subscriptionEndDate,
      reason: data.reason || 'Not specified'
    });

    return {
      success: true,
      message: 'Subscription cancelled successfully',
      activeUntil: userData.subscriptionEndDate
    };
  } catch (error) {
    console.error('Error cancelling subscription:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Add points to a user's account (for admins or system events)
exports.addPoints = functions.https.onCall(async (data, context) => {
  // Check if the caller is an admin
  if (!context.auth?.token?.admin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can add points'
    );
  }

  const { userId, points, reason } = data;

  if (!userId || !points || points <= 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Valid user ID and positive points value required'
    );
  }

  try {
    // Get current points
    const userRef = db.collection('users').doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const currentPoints = userDoc.data().points || 0;

    // Update points
    await userRef.update({
      points: currentPoints + points
    });

    // Log the points transaction
    await db.collection('pointsTransactions').add({
      userId: userId,
      points: points,
      type: 'credit',
      reason: reason || 'Admin adjustment',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      adminId: context.auth.uid
    });

    return {
      success: true,
      currentPoints: currentPoints + points
    };
  } catch (error) {
    console.error('Error adding points:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Function to check if a payment was successful when UPI app returns to the app
exports.checkPaymentStatus = functions.https.onCall(async (data, context) => {
  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to check payment status'
    );
  }

  const { transactionId } = data;

  if (!transactionId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Transaction ID is required'
    );
  }

  try {
    // Get payment document
    const paymentRef = db.collection('payments').doc(transactionId);
    const paymentDoc = await paymentRef.get();

    if (!paymentDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Transaction not found');
    }

    const paymentData = paymentDoc.data();

    // Security check: Only allow users to check their own payments
    if (paymentData.userId !== context.auth.uid) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Users can only check their own payments'
      );
    }

    // In a real-world scenario, you would call your payment gateway's API to check the status
    // For demo purposes, we'll just return the current status
    return {
      status: paymentData.status,
      timestamp: paymentData.timestamp,
      amount: paymentData.amount,
      planType: paymentData.planType
    };
  } catch (error) {
    console.error('Error checking payment status:', error);
    throw new functions.https.HttpsError('internal', error.message);
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
  }, async (context) => {kk
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