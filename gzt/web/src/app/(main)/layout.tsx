import Sidebar from "@/components/Sidebar";

export default function MainLayout({
    children,
}: Readonly<{
    children: React.ReactNode;
}>) {
    return (
        <div className="flex h-full w-full">
            <Sidebar />
            <div className="flex-1 overflow-auto bg-muted/20" style={{ outline: 'none' }} tabIndex={-1}>
                {children}
            </div>
        </div>
    );
}
