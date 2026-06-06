import { MapPin, Flower, Grid2x2 } from "lucide-react";
import { useNavigate, useLocation } from "react-router";

export default function BottomNav() {
  const navigate = useNavigate();
  const location = useLocation();

  const tabs = [
    { id: "map", label: "漫游", icon: MapPin, path: "/" },
    { id: "album", label: "相册", icon: Flower, path: "/album" },
    { id: "memory", label: "相簿", icon: Grid2x2, path: "/memory" },
  ];

  const getCurrentTab = () => {
    if (location.pathname === "/") return "map";
    if (location.pathname === "/album") return "album";
    if (location.pathname === "/memory") return "memory";
    return "map";
  };

  const currentTab = getCurrentTab();

  return (
    <div className="absolute bottom-[34px] left-0 right-0 flex justify-center z-50 pointer-events-none">
      <div 
        className="bg-white rounded-full flex items-center gap-8 px-8 pointer-events-auto"
        style={{
          width: '220px',
          height: '56px',
          boxShadow: 'var(--app-shadow-soft)',
        }}
      >
        {tabs.map((tab) => {
          const Icon = tab.icon;
          const isActive = currentTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => navigate(tab.path)}
              className="flex flex-col items-center gap-0.5 transition-colors"
            >
              <Icon 
                size={20} 
                strokeWidth={2}
                style={{ 
                  color: isActive ? 'var(--app-accent-blue)' : 'var(--app-text-secondary)'
                }} 
              />
              <span 
                style={{ 
                  fontSize: '10px',
                  fontWeight: 500,
                  color: isActive ? 'var(--app-accent-blue)' : 'var(--app-text-secondary)'
                }}
              >
                {tab.label}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
