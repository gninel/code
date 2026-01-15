export const getStaticLink = (path: string) => {
    // For file:// protocol support (static export without server)
    // We assume the export is flat or structure is preserved.

    // Split path and query
    const [pathname, search] = path.split('?');

    // If path is '/', it maps to 'index.html'
    if (pathname === '/') return './index.html' + (search ? `?${search}` : '');

    // Remove leading slash for relative link
    const cleanPath = pathname.startsWith('/') ? pathname.slice(1) : pathname;

    // Append .html for static files
    return `./${cleanPath}.html` + (search ? `?${search}` : '');
};

export const handleStaticNavigation = (router: any, path: string) => {
    // In a real browser environment with file://, Next.js router might fail 
    // because it expects pushstate to work with paths.
    // For "Double Click" static usage, we usually need full page reload via window.location 
    // to go to the .html file.

    // Check if we are potentially in a static file environment (or just force it for this export)
    // A robust check is hard, but we can try:
    const isStaticFile = typeof window !== 'undefined' && window.location.protocol === 'file:';

    if (isStaticFile) {
        window.location.href = getStaticLink(path);
    } else {
        if (router) {
            router.push(path);
        } else {
            // Fallback if no router provided (e.g. simple link)
            window.open(path, '_blank');
        }
    }
};
