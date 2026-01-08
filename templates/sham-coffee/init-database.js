/**
 * تهيئة قاعدة البيانات الافتراضية لمشروع قهوة الشام
 * قم بتشغيل هذا الملف من Console المتصفح بعد فتح الموقع
 */

// تأكد من تهيئة Firebase أولاً
async function initializeShamCoffeeDatabase() {
    try {
        const RESTAURANT_ID = 'sham-coffee-1';
        const db = firebase.database();
        
        // بيانات المطعم
        await db.ref(`restaurant-system/restaurants/${RESTAURANT_ID}`).set({
            name: 'قهوة الشام',
            type: 'cafe',
            username: 'admin',
            password: 'admin123',
            status: 'active',
            phone: '99123456',
            address: 'قهوة الشام',
            createdAt: new Date().toISOString()
        });
        
        // بيانات المدير
        await db.ref(`restaurant-system/superAdmins/admin-1`).set({
            username: 'admin',
            password: 'admin123',
            name: 'المدير العام',
            createdAt: new Date().toISOString()
        });
        
        // بيانات الموقع
        await db.ref(`restaurant-system/sites/sham-coffee`).set({
            name: 'قهوة الشام',
            type: 'restaurant',
            url: 'https://sham-coffee.web.app',
            restaurantId: RESTAURANT_ID,
            status: 'active',
            createdAt: new Date().toISOString()
        });
        
        // تصنيفات افتراضية
        const categories = [
            { id: 'shisha', name: 'الشيشة', order: 1, icon: '💨' },
            { id: 'hot-drinks', name: 'المشروبات الساخنة', order: 2, icon: '☕' },
            { id: 'cold-drinks', name: 'المشروبات الباردة', order: 3, icon: '🧊' },
            { id: 'desserts', name: 'الحلويات', order: 4, icon: '🍰' },
            { id: 'snacks', name: 'المقبلات', order: 5, icon: '🥨' }
        ];
        
        for (const category of categories) {
            await db.ref(`restaurant-system/categories/${RESTAURANT_ID}/${category.id}`).set({
                name: category.name,
                order: category.order,
                icon: category.icon,
                active: true,
                createdAt: new Date().toISOString()
            });
        }
        
        console.log('✅ تم تهيئة قاعدة البيانات بنجاح!');
        alert('✅ تم تهيئة قاعدة البيانات بنجاح!');
        
    } catch (error) {
        console.error('❌ خطأ في تهيئة قاعدة البيانات:', error);
        alert('❌ خطأ في تهيئة قاعدة البيانات: ' + error.message);
    }
}

// تشغيل التهيئة
// initializeShamCoffeeDatabase();






