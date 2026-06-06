import { Search, SlidersHorizontal } from "lucide-react";
import { useState } from "react";
import { ImageWithFallback } from "./figma/ImageWithFallback";

interface PhotoCluster {
  id: string;
  location: string;
  count: number;
  latitude: number;
  longitude: number;
  photo: string;
}

export default function MapView() {
  const [selectedCluster, setSelectedCluster] = useState<PhotoCluster | null>(null);

  const clusters: PhotoCluster[] = [
    { 
      id: "1", 
      location: "黄山风景区", 
      count: 12, 
      latitude: 30.1, 
      longitude: 118.1,
      photo: "https://images.unsplash.com/photo-1501786223405-6d024d7c3b8d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzY2VuaWMlMjBsYW5kc2NhcGUlMjBtb3VudGFpbnxlbnwxfHx8fDE3ODA3MDU4NDZ8MA&ixlib=rb-4.1.0&q=80&w=1080"
    },
    { 
      id: "2", 
      location: "上海外滩", 
      count: 8, 
      latitude: 31.2, 
      longitude: 121.5,
      photo: "https://images.unsplash.com/photo-1449824913935-59a10b8d2000?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjaXR5JTIwc3RyZWV0JTIwdXJiYW58ZW58MXx8fHwxNzgwNzA1ODQ3fDA&ixlib=rb-4.1.0&q=80&w=1080"
    },
    { 
      id: "3", 
      location: "三亚海滩", 
      count: 24, 
      latitude: 18.3, 
      longitude: 109.5,
      photo: "https://images.unsplash.com/photo-1647962431451-d0fdaf1cf21c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxiZWFjaCUyMG9jZWFuJTIwc3Vuc2V0fGVufDF8fHx8MTc4MDY2MzI1N3ww&ixlib=rb-4.1.0&q=80&w=1080"
    },
  ];

  return (
    <div className="absolute inset-0 pt-[44px] pb-[124px]">
      {/* Map Background */}
      <div className="absolute inset-0" style={{ backgroundColor: '#E8E5D8' }}>
        {/* Simplified map pattern */}
        <svg className="w-full h-full opacity-20">
          <defs>
            <pattern id="map-pattern" x="0" y="0" width="100" height="100" patternUnits="userSpaceOnUse">
              <path d="M0 50 Q 25 25, 50 50 T 100 50" stroke="#B8B5A8" fill="none" strokeWidth="1"/>
              <path d="M50 0 Q 25 25, 0 50" stroke="#B8B5A8" fill="none" strokeWidth="1"/>
            </pattern>
          </defs>
          <rect width="100%" height="100%" fill="url(#map-pattern)" />
        </svg>

        {/* Photo Clusters */}
        {clusters.map((cluster, index) => (
          <button
            key={cluster.id}
            onClick={() => setSelectedCluster(cluster)}
            className="absolute"
            style={{
              top: `${25 + index * 20}%`,
              left: `${30 + index * 15}%`,
            }}
          >
            <div className="relative">
              <ImageWithFallback 
                src={cluster.photo}
                alt={cluster.location}
                className="w-[56px] h-[56px] rounded-full object-cover border-[3px] border-white"
                style={{ boxShadow: 'var(--app-shadow-soft)' }}
              />
              <div 
                className="absolute -top-1 -right-1 bg-[var(--app-accent-blue)] text-white rounded-full w-[20px] h-[20px] flex items-center justify-center"
                style={{ fontSize: 'var(--app-text-superscript)', fontWeight: 600 }}
              >
                {cluster.count}
              </div>
            </div>
          </button>
        ))}
      </div>

      {/* Search Bar */}
      <div className="absolute top-[60px] left-4 right-4 flex gap-2 z-10">
        <div 
          className="flex-1 bg-white rounded-2xl flex items-center gap-2 px-4"
          style={{ height: '44px', boxShadow: 'var(--app-shadow-soft)' }}
        >
          <Search size={18} style={{ color: 'var(--app-text-secondary)' }} />
          <input 
            type="text" 
            placeholder="搜索地点 / 时间"
            className="flex-1 bg-transparent outline-none"
            style={{ fontSize: 'var(--app-text-body)', color: 'var(--app-text-primary)' }}
          />
        </div>
        <button 
          className="bg-white rounded-full flex items-center justify-center"
          style={{ width: '44px', height: '44px', boxShadow: 'var(--app-shadow-soft)' }}
        >
          <SlidersHorizontal size={20} style={{ color: 'var(--app-text-primary)' }} />
        </button>
      </div>

      {/* Expanded Cluster Card */}
      {selectedCluster && (
        <div 
          className="absolute bottom-0 left-0 right-0 bg-white z-20 overflow-hidden"
          style={{ 
            borderTopLeftRadius: '20px', 
            borderTopRightRadius: '20px',
            boxShadow: '0 -4px 16px rgba(0, 0, 0, 0.1)',
            maxHeight: '50%',
          }}
        >
          <div className="p-4">
            <div className="flex items-center justify-between mb-3">
              <div>
                <h3 style={{ fontSize: 'var(--app-text-section)', fontWeight: 600, color: 'var(--app-text-primary)' }}>
                  {selectedCluster.location}
                </h3>
                <p style={{ fontSize: 'var(--app-text-caption)', color: 'var(--app-text-secondary)' }}>
                  {selectedCluster.count} 张照片
                </p>
              </div>
              <button 
                onClick={() => setSelectedCluster(null)}
                className="text-[var(--app-text-secondary)]"
                style={{ fontSize: 'var(--app-text-body)' }}
              >
                关闭
              </button>
            </div>

            {/* Photo Grid */}
            <div className="grid grid-cols-3 gap-1">
              {[...Array(Math.min(6, selectedCluster.count))].map((_, i) => (
                <div 
                  key={i}
                  className="aspect-square rounded-lg overflow-hidden"
                  style={{ backgroundColor: '#E5E5EA' }}
                >
                  <ImageWithFallback 
                    src={selectedCluster.photo}
                    alt={`${selectedCluster.location} ${i + 1}`}
                    className="w-full h-full object-cover"
                  />
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
