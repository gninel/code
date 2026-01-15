export default function StandaloneLayout({
    children,
}: Readonly<{
    children: React.ReactNode;
}>) {
    return (
        <div className="h-full w-full bg-white">
            {children}
        </div>
    );
}
