require('dotenv').config();
const { storage } = require("firebase-functions");
const functions = require("firebase-functions");
const functionsV2 = require("firebase-functions/v2");
const fetch = require('node-fetch');
const admin = require("firebase-admin");
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const nodemailer = require('nodemailer');
const axios = require('axios');
const express = require('express');
const app = express();

// Google Cloud Run requires listening on the environment's PORT (default is 8080)
const PORT = process.env.PORT || 8080;

app.get('/', (req, res) => {
  res.send('Cloud Run is working!');
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

// Initialize the app only once
admin.initializeApp();

exports.fetchAndStoreHolidays = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  const { country, year } = req.query;

  // Use environment variable for API key
  const apiKey = process.env.CALENDARIFIC_API_KEY || "sus8gIvZCBFdPdah2O24JGSXSpU2fUWc"; //very important api key

  try {
    const response = await axios.get(`https://calendarific.com/api/v2/holidays`, {
      params: {
        api_key: apiKey,
        country: country || 'IN',
        year: 2025 || new Date().getFullYear()
      }
    });
    console.log('API Response structure:', JSON.stringify(response.data, null, 2).slice(0, 500) + '...');
    if (!response.data.response || !Array.isArray(response.data.response.holidays)) {
        console.error('Unexpected API response structure:', response.data);
        res.status(500).json({
          error: 'Unexpected API response structure',
          data: response.data
        });
        return;
      }

    const holidays = response.data.response.holidays;

    // Store holidays to Firestore
    const db = admin.firestore();
    const batch = db.batch();

    // Create a collection reference with year and country
    const collectionRef = db.collection(`holidays_${country || 'IN'}_${2025 || new Date().getFullYear()}`);

    holidays.forEach(holiday => {
      const docRef = collectionRef.doc();
      batch.set(docRef, {
        name: holiday.name,
        description: holiday.description,
        date: holiday.date.iso,
        type: Array.isArray(holiday.type) ? holiday.type[0] : holiday.type
      });
    });

    await batch.commit();

    // Return the holidays data directly
    res.status(200).json(response.data);
  } catch (err) {
    console.error('Error fetching holidays:', err.message);

    // Return a more detailed error message
    res.status(500).json({
      error: 'Failed to fetch holidays',
      message: err.message,
      status: err.response?.status,
      data: err.response?.data
    });
  }
});


// Check if running in Firebase environment or local
const emailHost = process.env.EMAIL_HOST || functions.config().email?.host;
const emailUser = process.env.EMAIL_USER || functions.config().email?.user;
const emailPassword = process.env.EMAIL_PASSWORD || functions.config().email?.password;

// Create email transporter
const transporter = nodemailer.createTransport({
  host: emailHost,
  port: 465,
  secure: true,
  auth: {
    user: emailUser,
    pass: emailPassword
  }
});

// ====================== FILTER FUNCTIONS =====================================

// Primary filter function with improved error handling and consistent field mapping
exports.filterTemplates = functions.https.onCall(async (data, context) => {
  try {
    // Extract search parameters
    const searchTerm = data.searchTerm || "";
    const filters = data.filters || {};

    // Parse filters with default values
    const isPaid = filters.isPaid !== undefined ? filters.isPaid : null; // null means both
    const minRating = parseFloat(filters.minRating) || 0;
    const language = filters.language || null; // null means all languages

    console.log(`Filtering with: searchTerm=${searchTerm}, isPaid=${isPaid}, minRating=${minRating}, language=${language}`);

    // Results collection
    let results = [];

    // 1. Search in categories > templates collection
    try {
      const categoriesSnapshot = await admin.firestore().collection('categories').get();

      for (const categoryDoc of categoriesSnapshot.docs) {
        // Build query with applicable filters
        let query = categoryDoc.ref.collection('templates');

        // Apply isPaid filter if specified
        if (isPaid !== null) {
          query = query.where('isPaid', '==', isPaid);
        }

        // Apply rating filter if specified - use avgRatings field in categories
        if (minRating > 0) {
          query = query.where('avgRatings', '>=', minRating);
        }

        // Apply language filter if specified
        if (language) {
          query = query.where('language', '==', language);
        }

        const templatesSnapshot = await query.get();

        // Process results
        for (const doc of templatesSnapshot.docs) {
          const data = doc.data();

          // Text search filter (if search term is provided)
          if (!searchTerm ||
              (data.title && data.title.toLowerCase().includes(searchTerm.toLowerCase()))) {
            results.push({
              id: doc.id,
              title: data.title || "",
              imageUrl: data.imageURL || data.imageUrl || "",
              isPaid: data.isPaid || false,
              avgRating: data.avgRatings || 0,
              type: categoryDoc.id,
              language: data.language || "en",
              source: 'categories'
            });
          }
        }
      }
      console.log(`Found ${results.length} results from categories collection`);
    } catch (error) {
      console.error("Error searching categories collection:", error);
    }

    // 2. Search in templates collection (trending quotes)
    try {
      let templatesQuery = admin.firestore().collection('templates');

      // Apply filters - use averageRating field in templates collection
      if (isPaid !== null) {
        templatesQuery = templatesQuery.where('isPaid', '==', isPaid);
      }

      if (minRating > 0) {
        templatesQuery = templatesQuery.where('averageRating', '>=', minRating);
      }

      if (language) {
        templatesQuery = templatesQuery.where('language', '==', language);
      }

      const templatesSnapshot = await templatesQuery.get();

      for (const doc of templatesSnapshot.docs) {
        const data = doc.data();

        if (!searchTerm ||
            (data.title && data.title.toLowerCase().includes(searchTerm.toLowerCase()))) {
          results.push({
            id: doc.id,
            title: data.title || "",
            imageUrl: data.imageUrl || "",
            isPaid: data.isPaid || false,
            avgRating: data.averageRating || 0,
            type: data.category || "general",
            language: data.language || "en",
            source: 'templates'
          });
        }
      }
      console.log(`Found ${results.length} total results after templates collection`);
    } catch (error) {
      console.error("Error searching templates collection:", error);
    }

    // 3. Search in festivals collection
    try {
      const festivalsSnapshot = await admin.firestore().collection('festivals').get();

      for (const festivalDoc of festivalsSnapshot.docs) {
        const festivalData = festivalDoc.data();

        if (festivalData.templates && Array.isArray(festivalData.templates)) {
          // Process each template in the templates array
          festivalData.templates.forEach((template, index) => {
            // Apply filters
            const templateIsPaid = template.isPaid !== undefined ? template.isPaid : false;
            const templateLanguage = template.language || "en";

            // Check if template passes all filters
            if ((isPaid === null || templateIsPaid === isPaid) &&
                (language === null || templateLanguage === language)) {

              // For festival templates, we check against festival name for text search
              const festivalName = festivalData.name || "";

              if (!searchTerm ||
                  festivalName.toLowerCase().includes(searchTerm.toLowerCase())) {
                results.push({
                  id: `${festivalDoc.id}_${index}`,
                  title: festivalName || "Festival Post",
                  imageUrl: template.imageURL || template.imageUrl || "",
                  isPaid: templateIsPaid,
                  avgRating: 0, // Festivals don't have ratings in the current data model
                  type: "festival",
                  language: templateLanguage,
                  source: 'festivals'
                });
              }
            }
          });
        }
      }
      console.log(`Found ${results.length} total results after festivals collection`);
    } catch (error) {
      console.error("Error searching festivals collection:", error);
    }

    // 4. Search in totd collection (time of day quotes)
    try {
      const totdSnapshot = await admin.firestore().collection('totd').get();

      for (const timeDoc of totdSnapshot.docs) {
        const timeData = timeDoc.data();

        // Process each post field (post1, post2, etc.)
        Object.keys(timeData).forEach(key => {
          if (key.startsWith('post') && typeof timeData[key] === 'object') {
            const post = timeData[key];
            const postLanguage = post.language || "en";

            // Apply filters - use avgRating field in totd collection
            if ((isPaid === null || post.isPaid === isPaid) &&
                (minRating === 0 || (post.avgRating || 0) >= minRating) &&
                (language === null || postLanguage === language)) {

              if (!searchTerm ||
                  (post.title && post.title.toLowerCase().includes(searchTerm.toLowerCase()))) {
                results.push({
                  id: `${timeDoc.id}_${key}`,
                  title: post.title || "Quote of the Day",
                  imageUrl: post.imageUrl || "",
                  isPaid: post.isPaid || false,
                  avgRating: post.avgRating || 0,
                  type: "time of day",
                  language: postLanguage,
                  source: 'totd'
                });
              }
            }
          }
        });
      }
      console.log(`Found ${results.length} total results after totd collection`);
    } catch (error) {
      console.error("Error searching totd collection:", error);
    }

    // Remove duplicates based on imageUrl to ensure unique templates
    const uniqueResults = [];
    const imageUrls = new Set();

    for (const result of results) {
      if (result.imageUrl && !imageUrls.has(result.imageUrl)) {
        imageUrls.add(result.imageUrl);
        uniqueResults.push(result);
      }
    }

    console.log(`Found ${uniqueResults.length} results after filtering and removing duplicates`);

    return { results: uniqueResults };
  } catch (error) {
    console.error("Error in filterTemplates function:", error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

exports.addLanguageField = functions.https.onCall(async (data, context) => {
  try {
    // Default language (assuming most content is in English)
    const defaultLanguage = data.defaultLanguage || "en";

    // Update categories > templates
    const categoriesSnapshot = await admin.firestore().collection('categories').get();
    let categoryUpdates = 0;

    for (const categoryDoc of categoriesSnapshot.docs) {
      const templatesSnapshot = await categoryDoc.ref.collection('templates').get();

      for (const templateDoc of templatesSnapshot.docs) {
        await templateDoc.ref.update({
          language: defaultLanguage
        });
        categoryUpdates++;
      }
    }

    // Update templates collection
    const templatesSnapshot = await admin.firestore().collection('templates').get();
    let templateUpdates = 0;

    for (const templateDoc of templatesSnapshot.docs) {
      await templateDoc.ref.update({
        language: defaultLanguage
      });
      templateUpdates++;
    }

    // Update festival templates
    const festivalsSnapshot = await admin.firestore().collection('festivals').get();
    let festivalUpdates = 0;

    for (const festivalDoc of festivalsSnapshot.docs) {
      const festivalData = festivalDoc.data();

      if (festivalData.templates && Array.isArray(festivalData.templates)) {
        // Update each template in the array
        const updatedTemplates = festivalData.templates.map(template => ({
          ...template,
          language: defaultLanguage
        }));

        await festivalDoc.ref.update({
          templates: updatedTemplates
        });
        festivalUpdates++;
      }
    }

    // Update totd collection
    const totdSnapshot = await admin.firestore().collection('totd').get();
    let totdUpdates = 0;

    for (const timeDoc of totdSnapshot.docs) {
      const timeData = timeDoc.data();
      const updatedTimeData = {};
      let hasUpdates = false;

      // Check each post field (post1, post2, etc.)
      Object.keys(timeData).forEach(key => {
        if (key.startsWith('post') && typeof timeData[key] === 'object') {
          updatedTimeData[key] = {
            ...timeData[key],
            language: defaultLanguage
          };
          hasUpdates = true;
        }
      });

      if (hasUpdates) {
        await timeDoc.ref.update(updatedTimeData);
        totdUpdates++;
      }
    }

    return {
      success: true,
      message: "Language field added to all templates",
      stats: {
        categoryTemplates: categoryUpdates,
        templates: templateUpdates,
        festivals: festivalUpdates,
        totd: totdUpdates
      }
    };
  } catch (error) {
    console.error("Error adding language field:", error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});




// ======================== WELCOME EMAIL ==================================

// Function to send welcome email
async function sendWelcomeEmail(userEmail, userName) {
  const mailOptions = {
    from: '"Vaky" <no-reply@vaky.app>',
    to: userEmail,
    subject: 'Welcome to Our Community!',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
        <img src="https://firebasestorage.googleapis.com/v0/b/mind-turf.firebasestorage.app/o/logo%2FVaky_withoutbg.png?alt=media&token=75898268-e9bc-41b4-a07e-dec7a970a6bb" alt="Logo" style="display: block; margin: 0 auto; width: 100px;">
        <h2 style="color: #4285f4; text-align: center;">Welcome to Our Community!</h2>
        <p>Hello,</p>
        <p>Thank you for joining our community! We're excited to have you on board.</p>
        <p>With your verified account, you now have access to all features of our app:</p>
        <ul>
          <li>Browse and save your favorite quotes</li>
          <li>Customize your profile</li>
          <li>Connect with others</li>
          <li>And much more!</li>
        </ul>
        <p>Don't hesitate to reach out if you have any questions or feedback.</p>
        <div style="text-align: center; margin-top: 30px;">
          <a href="https://your-app-url.com" style="background-color: #4285f4; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Open App</a>
        </div>
        <p style="margin-top: 30px; font-size: 12px; color: #666; text-align: center;">
          This email was sent to ${userEmail}. If you did not sign up for an account, please disregard this email.
        </p>
      </div>
    `
  };
  
  try {
    await transporter.sendMail(mailOptions);
    console.log('Welcome email sent to:', userEmail);
    return { success: true };
  } catch (error) {
    console.error('Error sending welcome email:', error);
    return { success: false, error: error.message };
  }
}

// Function for handling new user documents (for Google sign-ins)
exports.handleNewGoogleUser = onDocumentCreated('users/{userDocId}', async (event) => {
  const userData = event.data.data();
  
  if (!userData) {
    console.log('No user data available');
    return null;
  }
  
  // Check if this is a Google sign-in and welcome email hasn't been sent yet
  if ((userData.provider === 'google.com' || userData.googleSignIn === true) && 
      !userData.welcomeEmailSent) {
    const userEmail = userData.email;
    const userName = userData.name || 'New User';
    
    // Send welcome email
    try {
      await sendWelcomeEmail(userEmail, userName);
      
      // Update the user document to mark that welcome email was sent
      await event.data.ref.update({
        welcomeEmailSent: true,
        welcomeEmailSentAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // Process referral if present
      if (userData.pendingReferralCode) {
        await processReferral(userData.uid, userData.pendingReferralCode, event.data.ref);
      }
      
      return { success: true };
    } catch (error) {
      console.error('Error sending welcome email:', error);
      return { success: false, error: error.message };
    }
  }
  
  return null;
});

// Function to process referral codes
async function processReferral(userId, referralCode, userDocRef) {
  try {
    // Find the referrer in Firestore
    const querySnapshot = await admin.firestore()
      .collection('users')
      .where('referralCode', '==', referralCode)
      .get();
    
    if (!querySnapshot.empty) {
      const referrerDoc = querySnapshot.docs[0];
      const referrerUid = referrerDoc.id;
      
      // Update new user with referrer info
      await userDocRef.update({
        referrerUid: referrerUid,
        rewardPoints: admin.firestore.FieldValue.increment(100) // Extra points for using referral
      });
      
      // Grant reward points to referrer
      await admin.firestore()
        .collection('users')
        .doc(referrerUid)
        .update({
          rewardPoints: admin.firestore.FieldValue.increment(50)
        });
      
      console.log(`Referral processed: ${userId} was referred by ${referrerUid}`);
    }
  } catch (error) {
    console.error('Error processing referral:', error);
  }
}

// Keep your original function for email verification
exports.sendWelcomeEmail = onDocumentUpdated('users/{userDocId}', async (event) => {
  const userDocId = event.params.userDocId;
  
  try {
    const previousData = event.data.before.data();
    const newData = event.data.after.data();
    
    if (!previousData || !newData) {
      console.log('No data available for comparison');
      return null;
    }
    
    // Check if this update represents an email verification
    if ((previousData.tempAccount === true && newData.tempAccount === false) || 
        (previousData.isEmailVerified === false && newData.isEmailVerified === true)) {
      
      // Skip if this is a returning user (welcome email already sent)
      if (newData.welcomeEmailSent === true) {
        console.log('Welcome email already sent to user:', newData.email);
        return null;
      }
      
      // User has just verified their email
      const userEmail = newData.email;
      const userName = newData.name || 'New User';
      
      await sendWelcomeEmail(userEmail, userName);
      
      // Update the user document to mark that welcome email was sent
      await event.data.after.ref.update({
        welcomeEmailSent: true,
        welcomeEmailSentAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      return { success: true };
    }
    
    return null;
  } catch (error) {
    console.error('Error in welcome email function:', error);
    return { success: false, error: error.message };
  }
});

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

// ============================== NOTIFICATION FUNCTIONS =============================

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
      const quoteText = qotdData.title;

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