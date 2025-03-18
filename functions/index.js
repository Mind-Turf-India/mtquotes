const functions = require("firebase-functions/v2");
const admin = require("firebase-admin");
const { DateTime } = require("luxon");

admin.initializeApp();

// QOTD Notification
exports.sendDailyQOTDNotification = functions.scheduler
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

// TOTD Morning Notification (6:00 AM)
exports.sendMorningTOTDNotification = functions.scheduler
  .onSchedule({
    schedule: "0 7 * * *", // Runs every day at 7 AM
    timeZone: "Asia/Kolkata",
  }, async (context) => {
    await sendTOTDNotification("morning", "Morning Thought");
  });

// TOTD Afternoon Notification (1:00 PM)
exports.sendAfternoonTOTDNotification = functions.scheduler
  .onSchedule({
    schedule: "0 13 * * *", // Runs every day at 1 PM
    timeZone: "Asia/Kolkata",
  }, async (context) => {
    await sendTOTDNotification("afternoon", "Afternoon Thought");
  });

// TOTD Evening Notification (6:00 PM)
exports.sendEveningTOTDNotification = functions.scheduler
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
// Festival Notifications (3:00 PM)
// Festival Notifications - Checks daily at 3 PM and sends notification for upcoming festivals
exports.checkAndSendFestivalNotifications = functions.scheduler
  .onSchedule({
    schedule: "0 15 * * *", // Runs every day at 3 PM Indian time (9 AM UTC)
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