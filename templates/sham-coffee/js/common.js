// Common functions for all pages

// Function to clear cache and reload
async function clearAppCache() {
    if (!confirm('هل تريد تحديث التطبيق ومسح الذاكرة المؤقتة؟ سيتم إعادة تحميل الصفحة.')) return;

    try {
        // 1. Unregister Service Workers
        if ('serviceWorker' in navigator) {
            const registrations = await navigator.serviceWorker.getRegistrations();
            for (const registration of registrations) {
                await registration.unregister();
            }
        }

        // 2. Delete all Caches
        if ('caches' in window) {
            const keys = await caches.keys();
            await Promise.all(keys.map(key => caches.delete(key)));
        }

        // 3. Reload page
        window.location.reload(true);
    } catch (error) {
        console.error('Error clearing cache:', error);
        alert('حدث خطأ أثناء مسح الذاكرة المؤقتة. يرجى تحديث الصفحة يدوياً.');
        window.location.reload();
    }
}

// Make it available globally
window.clearAppCache = clearAppCache;





