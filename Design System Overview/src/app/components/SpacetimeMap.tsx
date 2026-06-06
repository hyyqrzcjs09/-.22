import { useEffect, useRef } from "react";
import mapboxgl from "mapbox-gl";
import "mapbox-gl/dist/mapbox-gl.css";
import { MAPBOX_TOKEN, MAPBOX_STYLE } from "../../lib/mapbox";
import { setMapLabelsToChinese } from "../../lib/mapboxTheme";
import { LOCATIONS, type Footprint } from "../../lib/profile";

// 共同点（擦肩）marker：地点照片 + 脉冲光圈 + 地点名
function makeBothEl(place: string): HTMLElement {
  const loc = LOCATIONS[place];
  const wrap = document.createElement("div");
  wrap.style.cssText = "position:relative;width:44px;height:44px;display:flex;align-items:center;justify-content:center;";

  const halo = document.createElement("div");
  halo.style.cssText =
    "position:absolute;width:44px;height:44px;border-radius:9999px;background:rgba(255,107,107,0.25);border:1.5px solid #FF6B6B;";
  const photo = document.createElement("div");
  photo.style.cssText =
    "width:30px;height:30px;border-radius:9999px;overflow:hidden;border:2px solid #FF6B6B;box-shadow:0 2px 6px rgba(0,0,0,0.3);background:#eee;";
  const img = document.createElement("img");
  img.src = loc.photo;
  img.style.cssText = "width:100%;height:100%;object-fit:cover;";
  photo.appendChild(img);

  const label = document.createElement("div");
  label.textContent = loc.name;
  label.style.cssText =
    "position:absolute;top:46px;left:50%;transform:translateX(-50%);white-space:nowrap;font-size:11px;font-weight:700;color:#1C1C1E;background:rgba(255,255,255,0.85);padding:1px 6px;border-radius:8px;";

  wrap.appendChild(halo);
  wrap.appendChild(photo);
  wrap.appendChild(label);
  return wrap;
}

// 单人独有的足迹点：小色点
function makeDotEl(color: string): HTMLElement {
  const dot = document.createElement("div");
  dot.style.cssText = `width:13px;height:13px;border-radius:9999px;background:${color};border:2px solid #fff;box-shadow:0 1px 4px rgba(0,0,0,0.3);`;
  return dot;
}

export default function SpacetimeMap({ mine, theirs }: { mine: Footprint[]; theirs: Footprint[] }) {
  const container = useRef<HTMLDivElement | null>(null);
  const map = useRef<mapboxgl.Map | null>(null);

  useEffect(() => {
    if (!container.current || map.current) return;

    mapboxgl.accessToken = MAPBOX_TOKEN;
    map.current = new mapboxgl.Map({
      container: container.current,
      style: MAPBOX_STYLE,
      center: [118.793, 32.049],
      zoom: 11.4,
      interactive: false,
      attributionControl: false,
    });
    map.current.on("style.load", () => {
      if (map.current) setMapLabelsToChinese(map.current);
    });
    map.current.on("load", () => map.current?.resize());

    const ro = new ResizeObserver(() => map.current?.resize());
    ro.observe(container.current);

    const myPlaces = new Set(mine.map((f) => f.place));
    const theirPlaces = new Set(theirs.map((f) => f.place));
    const all = new Set([...myPlaces, ...theirPlaces]);

    for (const place of all) {
      const loc = LOCATIONS[place];
      if (!loc) continue;
      const both = myPlaces.has(place) && theirPlaces.has(place);
      let el: HTMLElement;
      if (both) el = makeBothEl(place);
      else el = makeDotEl(myPlaces.has(place) ? "#0A84FF" : "#FF6B6B"); // 蓝=你，粉=TA
      new mapboxgl.Marker({ element: el, anchor: "center" }).setLngLat(loc.lngLat).addTo(map.current!);
    }

    return () => {
      ro.disconnect();
      map.current?.remove();
      map.current = null;
    };
  }, []);

  return (
    <div className="relative w-full h-[190px] rounded-xl overflow-hidden">
      <div ref={container} style={{ position: "absolute", inset: 0 }} />
    </div>
  );
}
