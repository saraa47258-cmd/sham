/**
 * تهيئة بيانات تجريبية شاملة لمشروع قهوة الشام
 * قم باستدعاء initializeSampleData() من Console المتصفح
 */

async function initializeSampleData() {
    try {
        const RESTAURANT_ID = 'sham-coffee-1';
        const db = firebase.database();
        
        console.log('🚀 بدء تهيئة البيانات التجريبية...');
        
        // 1. بيانات المطعم (تحديث وليس استبدال)
        await db.ref(`restaurant-system/restaurants/${RESTAURANT_ID}`).update({
            name: 'قهوة الشام',
            type: 'cafe',
            username: 'admin',
            password: 'admin123',
            status: 'active',
            phone: '99123456',
            address: 'مسقط، سلطنة عُمان',
            email: 'info@shamcoffee.om',
            tables: 15,
            updatedAt: new Date().toISOString()
        });
        console.log('✅ تم تحديث بيانات المطعم');
        
        // 2. بيانات المدير
        await db.ref(`restaurant-system/superAdmins/admin-1`).set({
            username: 'admin',
            password: 'admin123',
            name: 'المدير العام',
            email: 'admin@shamcoffee.om',
            createdAt: new Date().toISOString()
        });
        console.log('✅ تم إضافة بيانات المدير');
        
        // 3. بيانات الموقع
        await db.ref(`restaurant-system/sites/sham-coffee`).set({
            name: 'قهوة الشام',
            type: 'restaurant',
            url: 'https://sham-coffee.web.app',
            restaurantId: RESTAURANT_ID,
            status: 'active',
            createdAt: new Date().toISOString()
        });
        console.log('✅ تم إضافة بيانات الموقع');
        
        // 4. التصنيفات
        const categories = [
            { id: 'shisha', name: 'الشيشة', order: 1, icon: '💨', emoji: '💨', active: true },
            { id: 'hot-drinks', name: 'المشروبات الساخنة', order: 2, icon: '☕', emoji: '☕', active: true },
            { id: 'cold-drinks', name: 'المشروبات الباردة', order: 3, icon: '🧊', emoji: '🧊', active: true },
            { id: 'desserts', name: 'الحلويات', order: 4, icon: '🍰', emoji: '🍰', active: true },
            { id: 'snacks', name: 'المقبلات', order: 5, icon: '🥨', emoji: '🥨', active: true },
            { id: 'breakfast', name: 'وجبات الإفطار', order: 6, icon: '🍳', emoji: '🍳', active: true }
        ];
        
        for (const category of categories) {
            await db.ref(`restaurant-system/restaurants/${RESTAURANT_ID}/categories/${category.id}`).set({
                name: category.name,
                order: category.order,
                icon: category.icon,
                emoji: category.emoji,
                active: category.active,
                createdAt: new Date().toISOString()
            });
        }
        console.log(`✅ تم إضافة ${categories.length} تصنيفات`);
        
        // 5. المنتجات - الشيشة (النكهات فقط، الأنواع في shishaTypes)
        const shishaFlavors = [
            { name: 'تفاح', description: 'شيشة بنكهة التفاح الطازجة', image: '🍎' },
            { name: 'عنب', description: 'شيشة بنكهة العنب الحلو', image: '🍇' },
            { name: 'فراولة', description: 'شيشة بنكهة الفراولة المميزة', image: '🍓' },
            { name: 'نعناع', description: 'شيشة بنكهة النعناع المنعشة', image: '🌿' },
            { name: 'ليمون ونعناع', description: 'خليط منعش من الليمون والنعناع', image: '🍋🌿' },
            { name: 'مشمش', description: 'شيشة بنكهة المشمش اللذيذة', image: '🍑' },
            { name: 'بطيخ', description: 'شيشة بنكهة البطيخ المنعشة', image: '🍉' },
            { name: 'خليط الفواكه', description: 'مزيج منعش من الفواكه المختلطة', image: '🍎🍊🍋' }
        ];
        
        // أنواع الشيشة مع الأسعار
        const shishaTypes = {
            'egyptian': { name: 'الشيشة المصرية', price: 2.000, icon: '💨', description: 'شيشة مصرية تقليدية' },
            'egyptian-ice': { name: 'الشيشة المصرية بالثلج', price: 2.500, icon: '🧊', description: 'شيشة مصرية مع ثلج' },
            'eym': { name: 'Eym', price: 3.000, icon: '⭐', description: 'شيشة Eym مميزة' },
            'spider': { name: 'السبايدر', price: 4.000, icon: '🕷️', description: 'شيشة السبايدر القوية' },
            'vip': { name: 'VIP', price: 10.000, icon: '👑', description: 'شيشة VIP فاخرة' }
        };
        
        // إضافة كل نكهة كمنتج مع أنواع الشيشة
        const shishaProducts = [];
        for (const flavor of shishaFlavors) {
            const productRef = db.ref(`restaurant-system/restaurants/${RESTAURANT_ID}/menu`).push();
            const productData = {
                name: flavor.name,
                price: 0, // السعر سيتم تحديده حسب النوع
                description: flavor.description,
                category: 'shisha',
                image: flavor.image,
                emoji: flavor.image,
                active: true,
                shishaTypes: shishaTypes, // إضافة أنواع الشيشة
                isShisha: true, // علامة أن هذا منتج شيشة
                createdAt: new Date().toISOString()
            };
            await productRef.set(productData);
            shishaProducts.push({ id: productRef.key, ...productData });
        }
        
        // 6. المنتجات - المشروبات الساخنة
        const hotDrinks = [
            { name: 'قهوة تركية', price: 1.500, description: 'قهوة تركية أصيلة', category: 'hot-drinks', image: '☕' },
            { name: 'قهوة عربية', price: 1.500, description: 'قهوة عربية تقليدية', category: 'hot-drinks', image: '☕' },
            { name: 'كابتشينو', price: 2.000, description: 'كابتشينو إيطالي مع حليب رغوي', category: 'hot-drinks', image: '☕' },
            { name: 'لاتيه', price: 2.000, description: 'لاتيه ناعم مع حليب ساخن', category: 'hot-drinks', image: '☕' },
            { name: 'إسبريسو', price: 1.800, description: 'إسبريسو قوي ومركّز', category: 'hot-drinks', image: '☕' },
            { name: 'شاي أحمر', price: 1.000, description: 'شاي أحمر تقليدي', category: 'hot-drinks', image: '🍵' },
            { name: 'شاي أخضر', price: 1.200, description: 'شاي أخضر صحي', category: 'hot-drinks', image: '🍵' },
            { name: 'شاي بالنعناع', price: 1.500, description: 'شاي بالنعناع الطازج', category: 'hot-drinks', image: '🍵' },
            { name: 'شوكولاتة ساخنة', price: 2.500, description: 'شوكولاتة ساخنة كريمية', category: 'hot-drinks', image: '☕' },
            { name: 'قرفة ساخنة', price: 1.800, description: 'مشروب القرفة الدافئ', category: 'hot-drinks', image: '☕' }
        ];
        
        // 7. المنتجات - المشروبات الباردة
        const coldDrinks = [
            { name: 'عصير برتقال', price: 2.000, description: 'عصير برتقال طبيعي', category: 'cold-drinks', image: '🧊' },
            { name: 'عصير تفاح', price: 2.000, description: 'عصير تفاح منعش', category: 'cold-drinks', image: '🧊' },
            { name: 'عصير فراولة', price: 2.500, description: 'عصير فراولة طبيعي', category: 'cold-drinks', image: '🧊' },
            { name: 'عصير مانجو', price: 2.500, description: 'عصير مانجو استوائي', category: 'cold-drinks', image: '🧊' },
            { name: 'عصير ليمون', price: 1.800, description: 'عصير ليمون منعش', category: 'cold-drinks', image: '🧊' },
            { name: 'ميلك شيك شوكولاتة', price: 3.500, description: 'ميلك شيك بالشوكولاتة', category: 'cold-drinks', image: '🥤' },
            { name: 'ميلك شيك فراولة', price: 3.500, description: 'ميلك شيك بالفراولة', category: 'cold-drinks', image: '🥤' },
            { name: 'مياه غازية', price: 1.000, description: 'مياه غازية باردة', category: 'cold-drinks', image: '🥤' },
            { name: 'آيس كوفي', price: 2.500, description: 'قهوة مثلجة', category: 'cold-drinks', image: '🧊' },
            { name: 'مشروبات الطاقة', price: 2.000, description: 'مشروب طاقة منعش', category: 'cold-drinks', image: '🥤' }
        ];
        
        // 8. المنتجات - الحلويات
        const desserts = [
            { name: 'كنافة', price: 3.000, description: 'كنافة نابلسية تقليدية', category: 'desserts', image: '🍰' },
            { name: 'بقلاوة', price: 3.500, description: 'بقلاوة بالجوز والفستق', category: 'desserts', image: '🍰' },
            { name: 'معمول', price: 2.500, description: 'معمول بالتمر والجوز', category: 'desserts', image: '🍪' },
            { name: 'كيك الشوكولاتة', price: 3.000, description: 'كيك شوكولاتة كريمي', category: 'desserts', image: '🎂' },
            { name: 'تشيز كيك', price: 3.500, description: 'تشيز كيك كلاسيكي', category: 'desserts', image: '🍰' },
            { name: 'أيس كريم', price: 2.500, description: 'آيس كريم بثلاث نكهات', category: 'desserts', image: '🍦' },
            { name: 'بسبوسة', price: 2.500, description: 'بسبوسة بالشربات', category: 'desserts', image: '🍰' },
            { name: 'لقيمات', price: 2.000, description: 'لقيمات دافئة مع العسل', category: 'desserts', image: '🍩' }
        ];
        
        // 9. المنتجات - المقبلات
        const snacks = [
            { name: 'مكسرات مشكلة', price: 4.000, description: 'مزيج من المكسرات المحمصة', category: 'snacks', image: '🥜' },
            { name: 'زيتون', price: 2.000, description: 'زيتون أخضر وأسود', category: 'snacks', image: '🫒' },
            { name: 'جبنة', price: 3.000, description: 'جبنة بيضاء طازجة', category: 'snacks', image: '🧀' },
            { name: 'حمص', price: 2.500, description: 'حمص بالطحينة', category: 'snacks', image: '🥄' },
            { name: 'متبل', price: 2.500, description: 'متبل بالفلفل والباذنجان', category: 'snacks', image: '🥄' },
            { name: 'بطاطس', price: 2.000, description: 'بطاطس مقلية', category: 'snacks', image: '🍟' },
            { name: 'فول', price: 2.000, description: 'فول مصري تقليدي', category: 'snacks', image: '🫘' }
        ];
        
        // 10. المنتجات - وجبات الإفطار
        const breakfast = [
            { name: 'أومليت', price: 3.500, description: 'أومليت بالجبن والخضار', category: 'breakfast', image: '🍳' },
            { name: 'بيض مقلي', price: 2.500, description: 'بيض مقلي مع خبز', category: 'breakfast', image: '🍳' },
            { name: 'فلافل', price: 2.000, description: 'فلافل مع طحينة', category: 'breakfast', image: '🥙' },
            { name: 'مناقيش', price: 2.500, description: 'مناقيش بالزعتر والجبن', category: 'breakfast', image: '🥯' },
            { name: 'حمص باللحمة', price: 4.000, description: 'حمص مع لحم مقدد', category: 'breakfast', image: '🥄' }
        ];
        
        // دمج جميع المنتجات الأخرى (الشيشة تم إضافتها مسبقاً)
        const allProducts = [
            ...hotDrinks,
            ...coldDrinks,
            ...desserts,
            ...snacks,
            ...breakfast
        ];
        
        // إضافة المنتجات الأخرى إلى Firebase
        for (const product of allProducts) {
            const productRef = db.ref(`restaurant-system/restaurants/${RESTAURANT_ID}/menu`).push();
            await productRef.set({
                name: product.name,
                price: product.price,
                description: product.description,
                category: product.category,
                image: product.image,
                emoji: product.image,
                active: true,
                featured: Math.random() > 0.8, // بعض المنتجات مميزة
                createdAt: new Date().toISOString()
            });
        }
        console.log(`✅ تم إضافة ${shishaProducts.length} نكهة شيشة مع ${Object.keys(shishaTypes).length} أنواع`);
        console.log(`✅ تم إضافة ${allProducts.length} منتج آخر`);
        
        // 11. العمال
        const workers = [
            { name: 'أحمد محمد', username: 'ahmed', password: '123456', position: 'نادل', phone: '99111111', active: true },
            { name: 'سارة علي', username: 'sara', password: '123456', position: 'كاشير', phone: '99222222', active: true },
            { name: 'خالد حسن', username: 'khaled', password: '123456', position: 'نادل', phone: '99333333', active: true },
            { name: 'فاطمة أحمد', username: 'fatima', password: '123456', position: 'كاشير', phone: '99444444', active: true }
        ];
        
        for (const worker of workers) {
            const workerRef = db.ref(`restaurant-system/workers/${RESTAURANT_ID}`).push();
            await workerRef.set({
                name: worker.name,
                username: worker.username,
                password: worker.password,
                position: worker.position,
                phone: worker.phone,
                active: worker.active,
                createdAt: new Date().toISOString()
            });
        }
        console.log(`✅ تم إضافة ${workers.length} عامل`);
        
        // 12. الغرف
        const rooms = [
            { name: 'غرفة VIP 1', capacity: 4, price: 15.000, status: 'available', icon: '👑' },
            { name: 'غرفة VIP 2', capacity: 6, price: 20.000, status: 'available', icon: '💎' },
            { name: 'غرفة عائلية 1', capacity: 8, price: 25.000, status: 'available', icon: '🛋️' },
            { name: 'غرفة عائلية 2', capacity: 10, price: 30.000, status: 'available', icon: '🏠' },
            { name: 'كوشة خارجية 1', capacity: 4, price: 12.000, status: 'available', icon: '🌴' },
            { name: 'كوشة خارجية 2', capacity: 6, price: 18.000, status: 'available', icon: '🌙' }
        ];
        
        for (const room of rooms) {
            const roomRef = db.ref(`restaurant-system/restaurants/${RESTAURANT_ID}/rooms`).push();
            await roomRef.set({
                name: room.name,
                capacity: room.capacity,
                price: room.price,
                status: room.status,
                icon: room.icon,
                createdAt: new Date().toISOString()
            });
        }
        console.log(`✅ تم إضافة ${rooms.length} غرفة`);
        
        // 13. بعض الطلبات التجريبية
        const sampleOrders = [
            {
                items: [
                    { id: '1', name: 'تفاح', quantity: 1, price: 3.500 },
                    { id: '2', name: 'قهوة تركية', quantity: 2, price: 1.500 }
                ],
                total: 6.500,
                status: 'completed',
                customerName: 'محمد أحمد',
                customerPhone: '99123456',
                createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
                restaurantId: RESTAURANT_ID
            },
            {
                items: [
                    { id: '3', name: 'عنب', quantity: 1, price: 3.500 },
                    { id: '4', name: 'كابتشينو', quantity: 1, price: 2.000 }
                ],
                total: 5.500,
                status: 'preparing',
                customerName: 'سارة خالد',
                customerPhone: '99234567',
                createdAt: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
                restaurantId: RESTAURANT_ID
            },
            {
                items: [
                    { id: '5', name: 'فراولة', quantity: 1, price: 3.500 },
                    { id: '6', name: 'عصير برتقال', quantity: 2, price: 2.000 },
                    { id: '7', name: 'كنافة', quantity: 1, price: 3.000 }
                ],
                total: 10.500,
                status: 'pending',
                customerName: 'أحمد علي',
                customerPhone: '99345678',
                createdAt: new Date().toISOString(),
                restaurantId: RESTAURANT_ID
            }
        ];
        
        for (const order of sampleOrders) {
            const orderRef = db.ref(`restaurant-system/restaurants/${RESTAURANT_ID}/orders`).push();
            await orderRef.set(order);
        }
        console.log(`✅ تم إضافة ${sampleOrders.length} طلب تجريبي`);
        
        // 14. بيانات المبيعات (لليوم)
        const today = new Date().toISOString().split('T')[0];
        await db.ref(`restaurant-system/restaurants/${RESTAURANT_ID}/sales/${today}`).set({
            ordersCount: sampleOrders.length,
            totalRevenue: sampleOrders.reduce((sum, o) => sum + o.total, 0),
            itemsSold: sampleOrders.reduce((sum, o) => sum + o.items.reduce((s, i) => s + i.quantity, 0), 0),
            cashPayments: 15.000,
            cardPayments: 7.500,
            updatedAt: new Date().toISOString()
        });
        console.log('✅ تم إضافة بيانات المبيعات');
        
        const totalProducts = shishaProducts.length + allProducts.length;
        console.log('🎉 تم إكمال تهيئة جميع البيانات التجريبية بنجاح!');
        alert('✅ تم إكمال تهيئة البيانات التجريبية بنجاح!\n\nتم إضافة:\n- 6 تصنيفات\n- ' + shishaProducts.length + ' نكهة شيشة (' + Object.keys(shishaTypes).length + ' أنواع)\n- ' + allProducts.length + ' منتج آخر\n- ' + workers.length + ' عامل\n- ' + rooms.length + ' غرفة\n- ' + sampleOrders.length + ' طلب تجريبي');
        
        // إعادة تحميل الصفحة
        setTimeout(() => {
            window.location.reload();
        }, 2000);
        
    } catch (error) {
        console.error('❌ خطأ في تهيئة البيانات:', error);
        alert('❌ حدث خطأ في تهيئة البيانات: ' + error.message);
    }
}

// جعل الدالة متاحة عالمياً
window.initializeSampleData = initializeSampleData;

