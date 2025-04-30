//const functions = require('firebase-functions');
//const admin = require('firebase-admin');
//
//// Primary filter function with improved error handling and consistent field mapping
//exports.filterTemplates = functions.https.onCall(async (data, context) => {
//  try {
//    // Extract search parameters
//    const searchTerm = data.searchTerm || "";
//    const filters = data.filters || {};
//
//    // Parse filters with default values
//    const isPaid = filters.isPaid !== undefined ? filters.isPaid : null; // null means both
//    const minRating = parseFloat(filters.minRating) || 0;
//    const language = filters.language || null; // null means all languages
//
//    console.log(`Filtering with: searchTerm=${searchTerm}, isPaid=${isPaid}, minRating=${minRating}, language=${language}`);
//
//    // Results collection
//    let results = [];
//
//    // 1. Search in categories > templates collection
//    try {
//      const categoriesSnapshot = await admin.firestore().collection('categories').get();
//
//      for (const categoryDoc of categoriesSnapshot.docs) {
//        // Build query with applicable filters
//        let query = categoryDoc.ref.collection('templates');
//
//        // Apply isPaid filter if specified
//        if (isPaid !== null) {
//          query = query.where('isPaid', '==', isPaid);
//        }
//
//        // Apply rating filter if specified - use avgRatings field in categories
//        if (minRating > 0) {
//          query = query.where('avgRatings', '>=', minRating);
//        }
//
//        // Apply language filter if specified
//        if (language) {
//          query = query.where('language', '==', language);
//        }
//
//        const templatesSnapshot = await query.get();
//
//        // Process results
//        for (const doc of templatesSnapshot.docs) {
//          const data = doc.data();
//
//          // Text search filter (if search term is provided)
//          if (!searchTerm ||
//              (data.title && data.title.toLowerCase().includes(searchTerm.toLowerCase()))) {
//            results.push({
//              id: doc.id,
//              title: data.title || "",
//              imageUrl: data.imageURL || data.imageUrl || "",
//              isPaid: data.isPaid || false,
//              avgRating: data.avgRatings || 0,
//              type: categoryDoc.id,
//              language: data.language || "en",
//              source: 'categories'
//            });
//          }
//        }
//      }
//      console.log(`Found ${results.length} results from categories collection`);
//    } catch (error) {
//      console.error("Error searching categories collection:", error);
//    }
//
//    // 2. Search in templates collection (trending quotes)
//    try {
//      let templatesQuery = admin.firestore().collection('templates');
//
//      // Apply filters - use averageRating field in templates collection
//      if (isPaid !== null) {
//        templatesQuery = templatesQuery.where('isPaid', '==', isPaid);
//      }
//
//      if (minRating > 0) {
//        templatesQuery = templatesQuery.where('averageRating', '>=', minRating);
//      }
//
//      if (language) {
//        templatesQuery = templatesQuery.where('language', '==', language);
//      }
//
//      const templatesSnapshot = await templatesQuery.get();
//
//      for (const doc of templatesSnapshot.docs) {
//        const data = doc.data();
//
//        if (!searchTerm ||
//            (data.title && data.title.toLowerCase().includes(searchTerm.toLowerCase()))) {
//          results.push({
//            id: doc.id,
//            title: data.title || "",
//            imageUrl: data.imageUrl || "",
//            isPaid: data.isPaid || false,
//            avgRating: data.averageRating || 0,
//            type: data.category || "general",
//            language: data.language || "en",
//            source: 'templates'
//          });
//        }
//      }
//      console.log(`Found ${results.length} total results after templates collection`);
//    } catch (error) {
//      console.error("Error searching templates collection:", error);
//    }
//
//    // 3. Search in festivals collection
//    try {
//      const festivalsSnapshot = await admin.firestore().collection('festivals').get();
//
//      for (const festivalDoc of festivalsSnapshot.docs) {
//        const festivalData = festivalDoc.data();
//
//        if (festivalData.templates && Array.isArray(festivalData.templates)) {
//          // Process each template in the templates array
//          festivalData.templates.forEach((template, index) => {
//            // Apply filters
//            const templateIsPaid = template.isPaid !== undefined ? template.isPaid : false;
//            const templateLanguage = template.language || "en";
//
//            // Check if template passes all filters
//            if ((isPaid === null || templateIsPaid === isPaid) &&
//                (language === null || templateLanguage === language)) {
//
//              // For festival templates, we check against festival name for text search
//              const festivalName = festivalData.name || "";
//
//              if (!searchTerm ||
//                  festivalName.toLowerCase().includes(searchTerm.toLowerCase())) {
//                results.push({
//                  id: `${festivalDoc.id}_${index}`,
//                  title: festivalName || "Festival Post",
//                  imageUrl: template.imageURL || template.imageUrl || "",
//                  isPaid: templateIsPaid,
//                  avgRating: 0, // Festivals don't have ratings in the current data model
//                  type: "festival",
//                  language: templateLanguage,
//                  source: 'festivals'
//                });
//              }
//            }
//          });
//        }
//      }
//      console.log(`Found ${results.length} total results after festivals collection`);
//    } catch (error) {
//      console.error("Error searching festivals collection:", error);
//    }
//
//    // 4. Search in totd collection (time of day quotes)
//    try {
//      const totdSnapshot = await admin.firestore().collection('totd').get();
//
//      for (const timeDoc of totdSnapshot.docs) {
//        const timeData = timeDoc.data();
//
//        // Process each post field (post1, post2, etc.)
//        Object.keys(timeData).forEach(key => {
//          if (key.startsWith('post') && typeof timeData[key] === 'object') {
//            const post = timeData[key];
//            const postLanguage = post.language || "en";
//
//            // Apply filters - use avgRating field in totd collection
//            if ((isPaid === null || post.isPaid === isPaid) &&
//                (minRating === 0 || (post.avgRating || 0) >= minRating) &&
//                (language === null || postLanguage === language)) {
//
//              if (!searchTerm ||
//                  (post.title && post.title.toLowerCase().includes(searchTerm.toLowerCase()))) {
//                results.push({
//                  id: `${timeDoc.id}_${key}`,
//                  title: post.title || "Quote of the Day",
//                  imageUrl: post.imageUrl || "",
//                  isPaid: post.isPaid || false,
//                  avgRating: post.avgRating || 0,
//                  type: "time of day",
//                  language: postLanguage,
//                  source: 'totd'
//                });
//              }
//            }
//          }
//        });
//      }
//      console.log(`Found ${results.length} total results after totd collection`);
//    } catch (error) {
//      console.error("Error searching totd collection:", error);
//    }
//
//    // Remove duplicates based on imageUrl to ensure unique templates
//    const uniqueResults = [];
//    const imageUrls = new Set();
//
//    for (const result of results) {
//      if (result.imageUrl && !imageUrls.has(result.imageUrl)) {
//        imageUrls.add(result.imageUrl);
//        uniqueResults.push(result);
//      }
//    }
//
//    console.log(`Found ${uniqueResults.length} results after filtering and removing duplicates`);
//
//    return { results: uniqueResults };
//  } catch (error) {
//    console.error("Error in filterTemplates function:", error);
//    throw new functions.https.HttpsError('internal', error.message);
//  }
//});
//
//exports.addLanguageField = functions.https.onCall(async (data, context) => {
//  try {
//    // Default language (assuming most content is in English)
//    const defaultLanguage = data.defaultLanguage || "en";
//
//    // Update categories > templates
//    const categoriesSnapshot = await admin.firestore().collection('categories').get();
//    let categoryUpdates = 0;
//
//    for (const categoryDoc of categoriesSnapshot.docs) {
//      const templatesSnapshot = await categoryDoc.ref.collection('templates').get();
//
//      for (const templateDoc of templatesSnapshot.docs) {
//        await templateDoc.ref.update({
//          language: defaultLanguage
//        });
//        categoryUpdates++;
//      }
//    }
//
//    // Update templates collection
//    const templatesSnapshot = await admin.firestore().collection('templates').get();
//    let templateUpdates = 0;
//
//    for (const templateDoc of templatesSnapshot.docs) {
//      await templateDoc.ref.update({
//        language: defaultLanguage
//      });
//      templateUpdates++;
//    }
//
//    // Update festival templates
//    const festivalsSnapshot = await admin.firestore().collection('festivals').get();
//    let festivalUpdates = 0;
//
//    for (const festivalDoc of festivalsSnapshot.docs) {
//      const festivalData = festivalDoc.data();
//
//      if (festivalData.templates && Array.isArray(festivalData.templates)) {
//        // Update each template in the array
//        const updatedTemplates = festivalData.templates.map(template => ({
//          ...template,
//          language: defaultLanguage
//        }));
//
//        await festivalDoc.ref.update({
//          templates: updatedTemplates
//        });
//        festivalUpdates++;
//      }
//    }
//
//    // Update totd collection
//    const totdSnapshot = await admin.firestore().collection('totd').get();
//    let totdUpdates = 0;
//
//    for (const timeDoc of totdSnapshot.docs) {
//      const timeData = timeDoc.data();
//      const updatedTimeData = {};
//      let hasUpdates = false;
//
//      // Check each post field (post1, post2, etc.)
//      Object.keys(timeData).forEach(key => {
//        if (key.startsWith('post') && typeof timeData[key] === 'object') {
//          updatedTimeData[key] = {
//            ...timeData[key],
//            language: defaultLanguage
//          };
//          hasUpdates = true;
//        }
//      });
//
//      if (hasUpdates) {
//        await timeDoc.ref.update(updatedTimeData);
//        totdUpdates++;
//      }
//    }
//
//    return {
//      success: true,
//      message: "Language field added to all templates",
//      stats: {
//        categoryTemplates: categoryUpdates,
//        templates: templateUpdates,
//        festivals: festivalUpdates,
//        totd: totdUpdates
//      }
//    };
//  } catch (error) {
//    console.error("Error adding language field:", error);
//    throw new functions.https.HttpsError('internal', error.message);
//  }
//});