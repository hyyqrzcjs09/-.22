import { Battery, Signal, Wifi } from "lucide-react";

export default function StatusBar() {
  return (
    <div className="absolute top-0 left-0 right-0 h-[44px] flex items-center justify-between px-6 text-[var(--app-text-primary)] z-50">
      {/* Left - Time */}
      <div className="flex-1">
        <span style={{ fontSize: '15px', fontWeight: 600 }}>15:09</span>
      </div>

      {/* Center - Dynamic Island */}
      <div className="flex-none">
        <div className="w-[120px] h-[36px] bg-black rounded-full"></div>
      </div>

      {/* Right - Status Icons */}
      <div className="flex-1 flex items-center justify-end gap-1.5">
        <Signal size={16} strokeWidth={2.5} />
        <Wifi size={16} strokeWidth={2.5} />
        <div className="flex items-center gap-0.5">
          <Battery size={20} strokeWidth={2.5} className="text-green-500" fill="currentColor" />
        </div>
      </div>
    </div>
  );
}
