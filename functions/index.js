const functions = require("firebase-functions/v2");
const admin = require("firebase-admin");
const { DateTime } = require("luxon");

admin.initializeApp();
//qotd
exports.sendDailyQOTDNotification = functions.scheduler
  .onSchedule({
    schedule: "22 23 * * *", // Runs every day at 9 AM
    timeZone: "Asia/Kolkata", // Set to your time zone
  }, async (context) => {
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

    // Create notification payload with platform-specific configurations
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
  });

//qotd ends

exports.sendMorningTOTDNotification = functions.scheduler
  .onSchedule({
    schedule: "0 6 * * *", // Runs every day at 7 AM
    timeZone: "Asia/Kolkata",
  }, async (context) => {
    await sendTOTDNotification("morning", "Morning Thought");
  });

// TOTD Afternoon Notification (12:00 PM)
exports.sendAfternoonTOTDNotification = functions.scheduler
  .onSchedule({
    schedule: "0 13 * * *", // Runs every day at 12 PM
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
      .filter(key => key.startsWith('post') && totdData[key].imageUrl && totdData[key].title);

    if (posts.length === 0) {
      console.log(`No valid posts found for ${timeOfDay} TOTD.`);
      return;
    }

    // Randomly select one post from the available posts
    const randomPostKey = posts[Math.floor(Math.random() * posts.length)];
    const selectedPost = totdData[randomPostKey];

    // Extract the data from the selected post
    const imageUrl = selectedPost.imageUrl;
    const title = selectedPost.title || "Thought of the Day"; // Fallback if title is empty

    // Create notification payload with platform-specific configurations
    const payload = {
      notification: {
        title: notificationTitle,
        body: title,
      },
      android: {
        notification: {
          imageUrl: imageUrl,
          priority: "high",
          visibility: "public"
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
          imageUrl: imageUrl
        }
      },
      topic: "totd",
    };

    await admin.messaging().send(payload);
    console.log(`${timeOfDay.toUpperCase()} TOTD Notification Sent: "${title}" with image: ${imageUrl}`);
  } catch (error) {
    console.error(`Error sending ${timeOfDay} TOTD notification:`, error);
  }
}

//festivals
exports.sendFestivalNotifications = functions.scheduler
  .onSchedule({
    schedule: "0 15 * * *", // Runs every day at 3 PM
    timeZone: "Asia/Kolkata",
  }, async (context) => {
    try {
      const now = DateTime.now().setZone("Asia/Kolkata");

      // Get all festivals from the collection
      const festivalsSnapshot = await admin.firestore().collection("festivals").get();

      if (festivalsSnapshot.empty) {
        console.log("No festivals found in the database.");
        return;
      }

      // Check each festival
      for (const festivalDoc of festivalsSnapshot.docs) {
        const festivalData = festivalDoc.data();

        // Skip if no festival date or templates
        if (!festivalData.festivalDate || !festivalData.templates || festivalData.templates.length === 0) {
          console.log(`Festival ${festivalDoc.id} missing required data, skipping.`);
          continue;
        }

        const festivalDate = DateTime.fromJSDate(festivalData.festivalDate.toDate()).setZone("Asia/Kolkata");
        const daysBefore = festivalData.showDaysBefore || 7; // Default to 7 days if not specified

        // Calculate days until festival
        const daysUntilFestival = Math.ceil(festivalDate.diff(now, 'days').days);

        // Check if we should send notification (within the range of days before the festival or on the festival day)
        if (daysUntilFestival >= 0 && daysUntilFestival <= daysBefore) {
          console.log(`Sending notification for ${festivalData.name}. Festival in ${daysUntilFestival} days.`);

          // Select a template based on days until festival
          // We can pick a different template each day to keep the content fresh
          // Or we can pick templates sequentially or randomly
          const templateIndex = daysUntilFestival % festivalData.templates.length;
          const selectedTemplate = festivalData.templates[templateIndex];

          if (!selectedTemplate || !selectedTemplate.imageURL) {
            console.log(`No valid template found for ${festivalData.name} at index ${templateIndex}`);
            continue;
          }

          let notificationTitle = `${festivalData.name} is coming!`;
          let notificationBody = `${daysUntilFestival} days until ${festivalData.name}`;

          // Special message on the festival day
          if (daysUntilFestival === 0) {
            notificationTitle = `Happy ${festivalData.name}!`;
            notificationBody = `Wishing you a wonderful ${festivalData.name}`;
          }

          // Create notification payload
          const payload = {
            notification: {
              title: notificationTitle,
              body: notificationBody,
            },
            android: {
              notification: {
                imageUrl: selectedTemplate.imageURL,
                priority: "high",
                visibility: "public"
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
                imageUrl: selectedTemplate.imageURL
              }
            },
            topic: "festivals",
          };

          await admin.messaging().send(payload);
          console.log(`Festival notification sent for ${festivalData.name}: "${notificationTitle}"`);
        }
      }
    } catch (error) {
      console.error("Error sending festival notifications:", error);
    }
  });