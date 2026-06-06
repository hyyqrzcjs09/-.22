import { Outlet } from "react-router";
import StatusBar from "./StatusBar";
import BottomNav from "./BottomNav";

export default function Root() {
  return (
    <div className="size-full flex items-center justify-center" style={{ backgroundColor: '#000' }}>
      {/* iPhone 16 Pro Container */}
      <div 
        className="relative overflow-hidden"
        style={{
          width: '393px',
          height: '852px',
          borderRadius: '55px',
          backgroundColor: 'var(--app-bg-gray)',
        }}
      >
        <StatusBar />
        <Outlet />
        <BottomNav />
      </div>
    </div>
  );
}
