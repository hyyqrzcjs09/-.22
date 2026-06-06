import { Search, SlidersHorizontal } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import mapboxgl from "mapbox-gl";
import "mapbox-gl/dist/mapbox-gl.css";
import { ImageWithFallback } from "./figma/ImageWithFallback";
import { MAPBOX_TOKEN, MAPBOX_STYLE } from "../../lib/mapbox";
import { applySoftGreenParksTheme } from "../../lib/mapboxTheme";

interface PhotoCluster {
  id: string;
  location: string;
  count: number;
  latitude: number;
  longitude: number;
  photo: string;
}

const clusters: PhotoCluster[] = [
  {
    id: "1",
    location: "黄山风景区",
    count: 12,
    latitude: 30.1,
    longitude: 118.1,
    photo:
      "https://images.unsplash.com/photo-1501786223405-6d024d7c3b8d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzY2VuaWMlMjBsYW5kc2NhcGUlMjBtb3VudGFpbnxlbnwxfHx8fDE3ODA3MDU4NDZ8MA&ixlib=rb-4.1.0&q=80&w=1080",
  },
  {
    id: "2",
    location: "上海外滩",
    count: 8,
    latitude: 31.2,
    longitude: 121.5,
    photo:
      "https://images.unsplash.com/photo-1449824913935-59a10b8d2000?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjaXR5JTIwc3RyZWV0JTIwdXJiYW58ZW58MXx8fHwxNzgwNzA1ODQ3fDA&ixlib=rb-4.1.0&q=80&w=1080",
  },
  {
    id: "3",
    location: "三亚海滩",
    count: 24,
    latitude: 18.3,
    longitude: 109.5,
    photo:
      "https://images.unsplash.com/photo-1647962431451-d0fdaf1cf21c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxiZWFjaCUyMG9jZWFuJTIwc3Vuc2V0fGVufDF8fHx8MTc4MDY2MzI1N3ww&ixlib=rb-4.1.0&q=80&w=1080",
  },
];

// 构建一个照片簇的自定义 marker DOM（白边圆形照片 + 数量角标），与原设计保持一致
function createClusterMarkerElement(cluster: PhotoCluster): HTMLElement {
  const wrapper = document.createElement("div");
  wrapper.style.cursor = "pointer";
  wrapper.style.position = "relative";
  wrapper.style.width = "56px";
  wrapper.style.height = "56px";

  const img = document.createElement("img");
  img.src = cluster.photo;
  img.alt = cluster.location;
  img.style.width = "56px";
  img.style.height = "56px";
  img.style.borderRadius = "9999px";
  img.style.objectFit = "cover";
  img.style.border = "3px solid #ffffff";
  img.style.boxShadow = "var(--app-shadow-soft, 0 2px 8px rgba(0,0,0,0.15))";
  img.style.display = "block";

  const badge = document.createElement("div");
  badge.textContent = String(cluster.count);
  badge.style.position = "absolute";
  badge.style.top = "-4px";
  badge.style.right = "-4px";
  badge.style.minWidth = "20px";
  badge.style.height = "20px";
  badge.style.padding = "0 4px";
  badge.style.borderRadius = "9999px";
  badge.style.background = "var(--app-accent-blue, #3478f6)";
  badge.style.color = "#ffffff";
  badge.style.fontSize = "var(--app-text-superscript, 11px)";
  badge.style.fontWeight = "600";
  badge.style.display = "flex";
  badge.style.alignItems = "center";
  badge.style.justifyContent = "center";
  badge.style.boxSizing = "border-box";

  wrapper.appendChild(img);
  wrapper.appendChild(badge);
  return wrapper;
}

export default function MapView() {
  const [selectedCluster, setSelectedCluster] = useState<PhotoCluster | null>(null);
  const mapContainer = useRef<HTMLDivElement>(null);
  const map = useRef<mapboxgl.Map | null>(null);

  // 初始化 Mapbox 地图
  useEffect(() => {
    if (!mapContainer.current || map.current) return;

    mapboxgl.accessToken = MAPBOX_TOKEN;

    map.current = new mapboxgl.Map({
      container: mapContainer.current,
      style: MAPBOX_STYLE,
      // 让黄山 / 上海 / 三亚三处照片簇都落在视野内
      center: [116, 25],
      zoom: 3.6,
      attributionControl: false,
      interactive: true,
    });

    map.current.addControl(
      new mapboxgl.NavigationControl({ showCompass: false }),
      "bottom-right"
    );

    map.current.on("style.load", () => {
      if (map.current) applySoftGreenParksTheme(map.current);
    });

    // 添加照片簇 marker
    clusters.forEach((cluster) => {
      const el = createClusterMarkerElement(cluster);
      el.addEventListener("click", (e) => {
        e.stopPropagation();
        setSelectedCluster(cluster);
        map.current?.flyTo({
          center: [cluster.longitude, cluster.latitude],
          zoom: 6,
          duration: 800,
        });
      });
      new mapboxgl.Marker({ element: el, anchor: "center" })
        .setLngLat([cluster.longitude, cluster.latitude])
        .addTo(map.current!);
    });

    return () => {
      map.current?.remove();
      map.current = null;
    };
  }, []);

  return (
    <div className="absolute inset-0 pt-[44px] pb-[124px]">
      {/* Mapbox 漫游底图 */}
      <div ref={mapContainer} className="absolute inset-0" />

      {/* Search Bar */}
      <div className="absolute top-[60px] left-4 right-4 flex gap-2 z-10">
        <div
          className="flex-1 bg-white rounded-2xl flex items-center gap-2 px-4"
          style={{ height: "44px", boxShadow: "var(--app-shadow-soft)" }}
        >
          <Search size={18} style={{ color: "var(--app-text-secondary)" }} />
          <input
            type="text"
            placeholder="搜索地点 / 时间"
            className="flex-1 bg-transparent outline-none"
            style={{ fontSize: "var(--app-text-body)", color: "var(--app-text-primary)" }}
          />
        </div>
        <button
          className="bg-white rounded-full flex items-center justify-center"
          style={{ width: "44px", height: "44px", boxShadow: "var(--app-shadow-soft)" }}
        >
          <SlidersHorizontal size={20} style={{ color: "var(--app-text-primary)" }} />
        </button>
      </div>

      {/* Expanded Cluster Card */}
      {selectedCluster && (
        <div
          className="absolute bottom-0 left-0 right-0 bg-white z-20 overflow-hidden"
          style={{
            borderTopLeftRadius: "20px",
            borderTopRightRadius: "20px",
            boxShadow: "0 -4px 16px rgba(0, 0, 0, 0.1)",
            maxHeight: "50%",
          }}
        >
          <div className="p-4">
            <div className="flex items-center justify-between mb-3">
              <div>
                <h3 style={{ fontSize: "var(--app-text-section)", fontWeight: 600, color: "var(--app-text-primary)" }}>
                  {selectedCluster.location}
                </h3>
                <p style={{ fontSize: "var(--app-text-caption)", color: "var(--app-text-secondary)" }}>
                  {selectedCluster.count} 张照片
                </p>
              </div>
              <button
                onClick={() => setSelectedCluster(null)}
                className="text-[var(--app-text-secondary)]"
                style={{ fontSize: "var(--app-text-body)" }}
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
                  style={{ backgroundColor: "#E5E5EA" }}
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
