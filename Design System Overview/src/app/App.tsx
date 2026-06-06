import React, { useState, useEffect, useRef } from 'react';
import {
  MapPin, Grid as GridIcon, Folder, Menu, LayoutGrid, CalendarDays,
  Clock, Map as MapViewIcon, ChevronLeft, CheckCircle2, Circle,
  Signal, Wifi, Battery, MapPinned, X, Edit2, LayoutTemplate, Map,
  Activity, Pause, Square, User, Plus, Images, Globe
} from 'lucide-react';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { motion, AnimatePresence } from 'motion/react';
import mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';
import { MAPBOX_TOKEN, MAPBOX_STYLE } from '../lib/mapbox';
import { applySoftGreenParksTheme, setMapLabelsToChinese } from '../lib/mapboxTheme';
import ARMatchScreen from './components/ARMatchScreen';

function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// --- MOCK DATA ---
const mapBgUrl = 'https://images.unsplash.com/photo-1568317711805-97917847953d?q=80&w=1080';

const rawPhotos = [
  { id: '1', url: 'https://images.unsplash.com/photo-1691201200746-9a95b64a3436?q=80&w=400', date: '2023/5/29 20:46', coordsString: '32.0760, 118.7970', album: '南京' },
  { id: '2', url: 'https://images.unsplash.com/photo-1575223970966-76ae61ee7838?q=80&w=400', date: '2023/5/30 14:20', coordsString: '32.0419, 118.7780', album: '南京' },
  { id: '3', url: 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?q=80&w=400', date: '2023/5/28 10:15', coordsString: '32.0220, 118.7880', album: '南京' },
  { id: '4', url: 'https://images.unsplash.com/photo-1589489873423-d1745278a8f4?q=80&w=400', date: '2023/6/02 09:00', coordsString: '32.0660, 118.7770', album: '南京' },
  { id: '5', url: 'https://images.unsplash.com/photo-1633722715463-d30f4f325e24?q=80&w=400', date: '2023/6/15 18:30', coordsString: '32.0610, 118.8530', album: '兔子🐶' },
  { id: '6', url: 'https://images.unsplash.com/photo-1747160262337-68a64efb183c?q=80&w=400', date: '2023/6/14 12:00', coordsString: '32.0500, 118.7900', album: '做饭' },
  { id: '7', url: 'https://images.unsplash.com/photo-1617634667039-8e4cb277ab46?q=80&w=400', date: '2023/6/14 08:45', coordsString: '32.0150, 118.7910', album: 'Picslog' },
  { id: '8', url: 'https://images.unsplash.com/photo-1556609894-0ae309cb8354?q=80&w=400', date: '2023/6/12 16:20', coordsString: '32.0840, 118.7920', album: 'Picslog' },
  { id: '9', url: 'https://images.unsplash.com/photo-1539136788836-5699e78bfc75?q=80&w=400', date: '2023/6/12 13:00', coordsString: '32.0360, 118.7700', album: '做饭' },
  { id: '10', url: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?q=80&w=400', date: '2023/6/10 20:00', coordsString: '32.0560, 118.8000', album: 'G.E.M' },
];

// 南京主城区的照片地点（真实经纬度）
const mapLocations = [
  {
    id: 'loc1',
    name: '玄武湖',
    coords: { x: 40, y: 35 },
    lngLat: [118.7970, 32.0760] as [number, number],
    photos: [rawPhotos[0], rawPhotos[1], rawPhotos[2], rawPhotos[3], rawPhotos[4], rawPhotos[5], rawPhotos[6], rawPhotos[7]]
  },
  {
    id: 'loc2',
    name: '新街口',
    coords: { x: 55, y: 65 },
    lngLat: [118.7780, 32.0419] as [number, number],
    photos: [rawPhotos[8], rawPhotos[9], rawPhotos[2]]
  },
  {
    id: 'loc3',
    name: '鼓楼',
    coords: { x: 30, y: 20 },
    lngLat: [118.7770, 32.0660] as [number, number],
    photos: [rawPhotos[3]]
  },
  {
    id: 'loc4',
    name: '夫子庙',
    coords: { x: 48, y: 55 },
    lngLat: [118.7880, 32.0220] as [number, number],
    photos: [rawPhotos[5], rawPhotos[6]]
  },
  {
    id: 'loc5',
    name: '明故宫',
    coords: { x: 45, y: 70 },
    lngLat: [118.8090, 32.0440] as [number, number],
    photos: [rawPhotos[7], rawPhotos[0], rawPhotos[1], rawPhotos[4]]
  }
];

const FIXED_OFFSETS = [
  { r: -12, x: -25, y: -15 },
  { r: 8, x: 20, y: 25 },
  { r: -5, x: -10, y: 15 },
  { r: 14, x: 30, y: -5 },
  { r: -15, x: -30, y: 30 },
  { r: 10, x: 10, y: -25 },
  { r: 0, x: 0, y: 0 },
  { r: -8, x: 25, y: 10 },
  { r: 12, x: -20, y: -20 },
  { r: -10, x: 5, y: 35 },
];

const albums = [
  { id: 'a1', name: 'G.E.M', count: 12 },
  { id: 'a2', name: 'Picslog', count: 48 },
  { id: 'a3', name: '做饭', count: 24 },
  { id: 'a4', name: '英国', count: 156 },
  { id: 'a5', name: '兔子🐶', count: 89 },
];

// MAGAZINE DATA
const yearsData = [
  { year: 2022, cover: 'https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9?q=80&w=400', color: '#14B8A6' },
  { year: 2023, cover: 'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?q=80&w=400', color: '#EAB308' },
  { year: 2024, cover: 'https://images.unsplash.com/photo-1542204165-65bf26472b9b?q=80&w=400', color: '#EF4444' },
  { year: 2025, cover: 'https://images.unsplash.com/photo-1490730141103-6cac27aaab94?q=80&w=400', color: '#3B82F6' },
  { year: 2026, cover: 'https://images.unsplash.com/photo-1506744626753-1fa44df31c78?q=80&w=400', color: '#8B5CF6' },
];

// TIMELINE DATA FOR PHOTOS SCREEN
const timelineData = [
  {
    id: 'd1',
    isSpecial: true,
    title: 'Yesterday',
    photos: [
      { id: 't1', url: 'https://picsum.photos/seed/t1/400/400', date: 'Yesterday 14:20' },
      { id: 't2', url: 'https://picsum.photos/seed/t2/400/400', date: 'Yesterday 16:30' },
      { id: 't3', url: 'https://picsum.photos/seed/t3/400/400', date: 'Yesterday 18:45' },
    ],
    offsets: [ { r: -6, y: 0 }, { r: 5, y: 8 }, { r: -3, y: 2 } ]
  },
  {
    id: 'd2',
    title: '7 June',
    subtitle: 'Saturday',
    photos: [
      { id: 't4', url: 'https://picsum.photos/seed/t4/400/400', date: '7 June 09:15' },
      { id: 't5', url: 'https://picsum.photos/seed/t5/400/400', date: '7 June 10:20' },
      { id: 't6', url: 'https://picsum.photos/seed/t6/400/400', date: '7 June 13:00' },
      { id: 't7', url: 'https://picsum.photos/seed/t7/400/400', date: '7 June 15:45' },
    ],
    offsets: [ { r: 4, y: 5 }, { r: -5, y: -2 }, { r: 7, y: 6 }, { r: -4, y: 0 } ]
  },
  {
    id: 'd3',
    title: '6 June',
    subtitle: 'Friday',
    photos: [
      { id: 't8', url: 'https://picsum.photos/seed/t8/400/400', date: '6 June 11:10' },
      { id: 't9', url: 'https://picsum.photos/seed/t9/400/400', date: '6 June 14:30' },
      { id: 't10', url: 'https://picsum.photos/seed/t10/400/400', date: '6 June 16:20' },
      { id: 't11', url: 'https://picsum.photos/seed/t11/400/400', date: '6 June 19:00' },
    ],
    offsets: [ { r: -7, y: 2 }, { r: 6, y: 7 }, { r: -2, y: -4 }, { r: 5, y: 4 } ]
  },
  {
    id: 'd4',
    title: '5 June',
    subtitle: 'Thursday',
    photos: [
      { id: 't12', url: 'https://picsum.photos/seed/t12/400/400', date: '5 June 08:30' },
      { id: 't13', url: 'https://picsum.photos/seed/t13/400/400', date: '5 June 10:45' },
      { id: 't14', url: 'https://picsum.photos/seed/t14/400/400', date: '5 June 12:20' },
    ],
    offsets: [ { r: 5, y: -3 }, { r: -6, y: 4 }, { r: 3, y: 0 } ]
  }
];

const calendarDays = [
  ...Array.from({length: 30}, (_, i) => {
    const d = i + 1;
    let p = null;
    if (d === 5) p = { url: 'https://picsum.photos/seed/c5/400/400', count: 3, id: 'c5' };
    if (d === 6) p = { url: 'https://picsum.photos/seed/c6/400/400', count: 8, id: 'c6' };
    if (d === 7) p = { url: 'https://picsum.photos/seed/c7/400/400', count: 2, id: 'c7' };
    if (d === 15) p = { url: 'https://picsum.photos/seed/c15/400/400', count: 12, id: 'c15' };
    if (d === 22) p = { url: 'https://picsum.photos/seed/c22/400/400', count: 5, id: 'c22' };
    if (d === 28) p = { url: 'https://picsum.photos/seed/c28/400/400', count: 1, id: 'c28' };
    
    return { day: d, inMonth: true, photo: p };
  }),
  ...Array.from({length: 5}, (_, i) => ({ day: i + 1, inMonth: false, photo: null }))
];

// --- APP COMPONENT ---
export default function App() {
  const [activeTab, setActiveTab] = useState<'map' | 'photos' | 'albums'>('map'); // 打开即进入南京主城区漫游地图

  return (
    <div className="flex items-center justify-center min-h-screen bg-neutral-100 p-4 font-sans selection:bg-[#0A84FF]/30">
      {/* iPhone 16 Pro Mockup Frame */}
      <div className="relative w-[393px] h-[852px] bg-[#F5F4F1] dark:bg-[#121212] text-[#1C1C1E] dark:text-white rounded-[55px] shadow-[0_0_0_12px_#000_inset,0_25px_50px_-12px_rgba(0,0,0,0.5)] overflow-hidden ring-1 ring-black/5">
        
        <div className="absolute inset-0 rounded-[55px] border-[12px] border-black pointer-events-none z-50"></div>

        {/* Status Bar */}
        <div className="absolute top-0 w-full h-14 flex items-center justify-between px-8 z-40 pointer-events-none text-black drop-shadow-sm">
          <span className="text-[15px] font-semibold mt-2 tracking-tight">9:41</span>
          <div className="flex items-center gap-1.5 mt-2">
            <Signal className="w-4 h-4 fill-current" />
            <Wifi className="w-4 h-4" />
            <Battery className="w-6 h-4" />
          </div>
        </div>

        {/* Dynamic Island */}
        <div className="absolute top-3 left-1/2 -translate-x-1/2 w-[120px] h-[32px] bg-black rounded-full z-40 pointer-events-none" />

        {/* Screen Content */}
        <div className="h-full w-full relative overflow-hidden bg-[#F5F4F1] dark:bg-[#121212]">
          <AnimatePresence mode="popLayout" initial={false}>
            <motion.div
              key={activeTab}
              initial={{ opacity: 0, scale: 0.98 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.98 }}
              transition={{ duration: 0.25, ease: 'easeOut' }}
              className="absolute inset-0 pt-14 pb-24 overflow-y-auto overflow-x-hidden scrollbar-hide"
            >
              {activeTab === 'map' && <MapScreen />}
              {activeTab === 'photos' && <PhotosScreen />}
              {activeTab === 'albums' && <ARMatchScreen />}
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Floating Bottom Tab Bar */}
        <div className="absolute bottom-8 left-1/2 -translate-x-1/2 w-[280px] bg-white/90 dark:bg-[#1E1E1E]/90 backdrop-blur-xl rounded-full shadow-[0_8px_32px_rgba(0,0,0,0.08)] px-2 py-2 flex justify-between items-center z-40 border border-black/5 dark:border-white/10">
          <TabButton 
            icon={<MapPinned className="w-6 h-6" />} 
            label="漫游地图" 
            isActive={activeTab === 'map'} 
            onClick={() => setActiveTab('map')} 
          />
          <TabButton 
            icon={<GridIcon className="w-6 h-6" />} 
            label="相册" 
            isActive={activeTab === 'photos'} 
            onClick={() => setActiveTab('photos')} 
          />
          <TabButton 
            icon={<Folder className="w-6 h-6 fill-current" />} 
            label="AR" 
            isActive={activeTab === 'albums'} 
            onClick={() => setActiveTab('albums')} 
          />
        </div>

      </div>

      <style dangerouslySetInnerHTML={{__html: `
        .scrollbar-hide::-webkit-scrollbar {
          display: none;
        }
        .scrollbar-hide {
          -ms-overflow-style: none;
          scrollbar-width: none;
        }
      `}} />
    </div>
  );
}

// --- SHARED COMPONENTS ---
function TabButton({ icon, label, isActive, onClick }: { icon: React.ReactNode, label: string, isActive: boolean, onClick: () => void }) {
  return (
    <button 
      onClick={onClick}
      className={cn(
        "relative flex flex-col items-center justify-center w-[80px] py-1 gap-1 transition-colors duration-200",
        isActive ? "text-[#0A84FF]" : "text-[#8E8E93] hover:text-gray-500"
      )}
    >
      <div className={cn("transition-transform duration-200", isActive && "scale-110")}>
        {icon}
      </div>
      <span className="text-[10px] font-medium">{label}</span>
    </button>
  );
}

// --- SCREENS ---

type ViewMode = 'scatter' | 'single';

// 缩放到此级别以下时，照片缩略图收缩成地图上的小蓝点（避免多个大圆挤在一起脱离地球）
const FAR_ZOOM = 11;

// 构建一个地点的 marker DOM：包含「照片缩略图」与「蓝点」两层，按 zoom 切换显示
function createLocationMarkerEl(loc: typeof mapLocations[0]): HTMLElement {
  const wrapper = document.createElement('div');
  // 注意：不要设 position，让 mapbox 自带的 .mapboxgl-marker{position:absolute} 生效，
  // 否则内联 position:relative 会覆盖它，导致所有 marker 在文档流里按 56px 堆叠、脱离地理位置。
  wrapper.style.cssText = 'width:56px;height:56px;cursor:pointer;';
  wrapper.className = 'roam-marker';

  // —— 放大时：白边圆形照片缩略图 + 数量角标 ——
  const thumb = document.createElement('div');
  thumb.className = 'roam-thumb';
  thumb.style.cssText = 'position:absolute;inset:0;';

  const ring = document.createElement('div');
  ring.style.cssText =
    'width:56px;height:56px;border-radius:9999px;border:3px solid #fff;overflow:hidden;background:#e5e7eb;box-shadow:0 4px 12px rgba(0,0,0,0.25);';
  const img = document.createElement('img');
  img.src = loc.photos[0].url;
  img.alt = loc.name;
  img.draggable = false;
  img.style.cssText = 'width:100%;height:100%;object-fit:cover;display:block;';
  ring.appendChild(img);
  thumb.appendChild(ring);

  if (loc.photos.length > 1) {
    const badge = document.createElement('div');
    badge.textContent = String(loc.photos.length);
    badge.style.cssText =
      'position:absolute;top:-4px;right:-8px;min-width:22px;height:22px;padding:0 6px;border-radius:9999px;background:rgba(0,0,0,0.8);border:1px solid rgba(255,255,255,0.2);color:#fff;font-size:12px;font-weight:700;display:flex;align-items:center;justify-content:center;box-sizing:border-box;';
    thumb.appendChild(badge);
  }
  wrapper.appendChild(thumb);

  // —— 缩小时：地图上的一个小蓝点（精确锚定在经纬度） ——
  const dot = document.createElement('div');
  dot.className = 'roam-dot';
  dot.style.cssText =
    'position:absolute;top:50%;left:50%;width:14px;height:14px;transform:translate(-50%,-50%);border-radius:9999px;background:#0A84FF;border:2.5px solid #fff;box-shadow:0 2px 6px rgba(0,0,0,0.35);display:none;';
  wrapper.appendChild(dot);

  return wrapper;
}

// 根据当前 zoom 切换每个 marker 显示「照片缩略图」还是「蓝点」
function applyMarkerZoomStyle(els: HTMLElement[], zoom: number) {
  const far = zoom < FAR_ZOOM;
  for (const el of els) {
    const thumb = el.querySelector<HTMLElement>('.roam-thumb');
    const dot = el.querySelector<HTMLElement>('.roam-dot');
    if (thumb) thumb.style.display = far ? 'none' : 'block';
    if (dot) dot.style.display = far ? 'block' : 'none';
  }
}

function MapScreen() {
  const [activeLoc, setActiveLoc] = useState<typeof mapLocations[0] | null>(null);
  const [viewMode, setViewMode] = useState<ViewMode>('scatter');
  const [currentIndex, setCurrentIndex] = useState(0);
  // 散开动画的起点（相对屏幕中心的像素偏移），点击 marker 时按地图投影实时计算
  const [origin, setOrigin] = useState({ x: 0, y: 0 });
  const originX = origin.x;
  const originY = origin.y;

  const mapContainer = useRef<HTMLDivElement | null>(null);
  const map = useRef<mapboxgl.Map | null>(null);

  // 地球自转
  const [spinning, setSpinning] = useState(false);
  const spinningRef = useRef(false);
  const userInteractingRef = useRef(false);
  const spinGlobeRef = useRef<() => void>(() => {});

  // 自转速度（倍率）
  const [spinSpeed, setSpinSpeed] = useState(1);
  const spinSpeedRef = useRef(1);
  const setSpeed = (v: number) => { spinSpeedRef.current = v; setSpinSpeed(v); };

  const closeOverlay = () => {
    setActiveLoc(null);
  };

  // 切换地球自转：放大状态下先飞回地球视图再转
  const toggleSpin = () => {
    const v = !spinningRef.current;
    spinningRef.current = v;
    setSpinning(v);
    const m = map.current;
    if (!m) return;
    if (v) {
      if (m.getZoom() > 4.5) {
        m.flyTo({ center: [118.793, 32.049], zoom: 2.6, duration: 1600 }); // moveend 后自动开始转
      } else {
        spinGlobeRef.current();
      }
    } else {
      m.stop(); // 停止当前缓动
    }
  };

  // 初始化 Mapbox 地图与照片地点 marker
  useEffect(() => {
    if (!mapContainer.current || map.current) return;

    mapboxgl.accessToken = MAPBOX_TOKEN;
    map.current = new mapboxgl.Map({
      container: mapContainer.current,
      style: MAPBOX_STYLE,
      center: [118.793, 32.049], // 南京主城区（点群中心）
      zoom: 12.2,
      attributionControl: false,
      interactive: true,
    });

    map.current.on('style.load', () => {
      if (!map.current) return;
      applySoftGreenParksTheme(map.current);
      setMapLabelsToChinese(map.current); // 地图文字改为中文
    });
    map.current.on('load', () => map.current?.resize());

    // 容器高度在挂载/切换动画后才稳定，用 ResizeObserver 持续校正地图尺寸
    const ro = new ResizeObserver(() => map.current?.resize());
    ro.observe(mapContainer.current);

    const markerEls: HTMLElement[] = [];
    mapLocations.forEach((loc) => {
      const el = createLocationMarkerEl(loc);
      el.addEventListener('click', (e) => {
        e.stopPropagation();
        // 蓝点（缩小）状态下点击不展开散开层，仅照片缩略图状态可展开
        if ((map.current?.getZoom() ?? 99) < FAR_ZOOM) return;
        // 以 marker 在地图上的投影点为散开动画起点
        const m = map.current;
        if (m) {
          const p = m.project(loc.lngLat);
          const c = m.getContainer();
          setOrigin({ x: p.x - c.clientWidth / 2, y: p.y - c.clientHeight / 2 });
        }
        setActiveLoc(loc);
        setViewMode('scatter');
        setCurrentIndex(0);
      });
      new mapboxgl.Marker({ element: el, anchor: 'center' })
        .setLngLat(loc.lngLat)
        .addTo(map.current!);
      markerEls.push(el);
    });

    // 缩放时切换照片缩略图 / 蓝点，并设置初始状态
    const onZoom = () => applyMarkerZoomStyle(markerEls, map.current?.getZoom() ?? 12);
    map.current.on('zoom', onZoom);
    onZoom();

    // —— 地球自转（参考 Mapbox spinning globe：用 moveend 链式 easeTo 实现匀速自转） ——
    const secondsPerRevolution = 120; // 一圈约 120 秒
    const maxSpinZoom = 5;            // 放大超过此级别就不再自转
    const slowSpinZoom = 3;           // 接近此级别时减速
    const spinGlobe = () => {
      const m = map.current;
      if (!m || !spinningRef.current || userInteractingRef.current) return;
      const zoom = m.getZoom();
      if (zoom >= maxSpinZoom) return;
      let degreesPerSecond = (360 / secondsPerRevolution) * spinSpeedRef.current;
      if (zoom > slowSpinZoom) {
        degreesPerSecond *= (maxSpinZoom - zoom) / (maxSpinZoom - slowSpinZoom);
      }
      const center = m.getCenter();
      center.lng -= degreesPerSecond;
      m.easeTo({ center, duration: 1000, easing: (n) => n });
    };
    spinGlobeRef.current = spinGlobe;

    const onInteractStart = () => { userInteractingRef.current = true; };
    const onInteractEnd = () => { userInteractingRef.current = false; spinGlobe(); };
    map.current.on('mousedown', onInteractStart);
    map.current.on('dragstart', onInteractStart);
    map.current.on('mouseup', onInteractEnd);
    map.current.on('touchend', onInteractEnd);
    map.current.on('moveend', spinGlobe);

    return () => {
      ro.disconnect();
      map.current?.off('zoom', onZoom);
      map.current?.remove();
      map.current = null;
    };
  }, []);

  return (
    <div className="relative w-full h-full bg-[#1C1C1E] overflow-hidden -mt-14 pt-14 text-white">
      {/* Mapbox 漫游底图（用内联样式强制 absolute 填满，避免被 mapbox-gl.css 的 .mapboxgl-map{position:relative} 覆盖） */}
      <div ref={mapContainer} style={{ position: 'absolute', top: 0, right: 0, bottom: 0, left: 0 }} />

      {/* Top Bar Overlay（不显示地点名；自转按钮 + 菜单按钮） */}
      <div className="absolute top-14 left-0 right-0 z-20 flex justify-end items-center gap-2 px-5 pointer-events-none">
        <button
          onClick={toggleSpin}
          className={cn(
            'w-10 h-10 rounded-full backdrop-blur-md flex items-center justify-center border shadow-sm pointer-events-auto transition-colors active:scale-95',
            spinning ? 'bg-[#0A84FF] border-[#0A84FF]' : 'bg-white/80 border-black/5'
          )}
          title="地球自转"
        >
          <Globe className={cn('w-5 h-5', spinning ? 'text-white animate-spin' : 'text-[#1C1C1E]')} style={spinning ? { animationDuration: '6s' } : undefined} />
        </button>
        <button className="w-10 h-10 rounded-full bg-white/80 backdrop-blur-md flex items-center justify-center border border-black/5 shadow-sm pointer-events-auto">
          <Menu className="w-5 h-5 text-[#1C1C1E]" />
        </button>
      </div>

      {/* 自转速度选择（仅自转时显示） */}
      <AnimatePresence>
        {spinning && (
          <motion.div
            initial={{ opacity: 0, y: -8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            transition={{ duration: 0.2 }}
            className="absolute top-[104px] left-1/2 -translate-x-1/2 z-20 pointer-events-auto flex items-center gap-1 bg-white/85 backdrop-blur-md rounded-full p-1 shadow-sm border border-black/5"
          >
            {[
              { v: 0.5, label: '0.5×' },
              { v: 1, label: '1×' },
              { v: 2, label: '2×' },
              { v: 4, label: '4×' },
            ].map((s) => (
              <button
                key={s.v}
                onClick={() => setSpeed(s.v)}
                className={cn(
                  'px-3 py-1 rounded-full text-[12px] font-semibold transition-colors',
                  spinSpeed === s.v ? 'bg-[#0A84FF] text-white' : 'text-[#1C1C1E] hover:bg-black/5'
                )}
              >
                {s.label}
              </button>
            ))}
          </motion.div>
        )}
      </AnimatePresence>

      {/* STATE 2 & 3: Overlay (Scatter & Single Modes) */}
      <AnimatePresence>
        {activeLoc && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.3 }}
            className="absolute inset-0 z-40 bg-white/60 backdrop-blur-[20px] overflow-hidden"
            onClick={closeOverlay} // Tapping empty area collapses everything
          >
            {/* Overlay Top Bar */}
            <div className="absolute top-14 left-0 right-0 px-4 flex justify-between items-center z-50 pointer-events-auto" onClick={e => e.stopPropagation()}>
              <button 
                onClick={closeOverlay} 
                className="w-10 h-10 rounded-full bg-black/10 flex items-center justify-center backdrop-blur-md transition-transform active:scale-90"
              >
                <ChevronLeft className="w-6 h-6 text-black -ml-0.5" />
              </button>
              
              <div className="bg-black/5 px-4 py-1.5 rounded-full backdrop-blur-md text-black font-semibold text-[14px]">
                {activeLoc.name} · {activeLoc.photos.length} 张照片
              </div>
              
              <button 
                onClick={() => setViewMode(v => v === 'scatter' ? 'single' : 'scatter')} 
                className="w-10 h-10 rounded-full bg-black/10 flex items-center justify-center backdrop-blur-md transition-transform active:scale-90"
              >
                 {viewMode === 'scatter' ? <LayoutGrid className="w-5 h-5 text-black" /> : <Map className="w-5 h-5 text-black" />}
              </button>
            </div>

            {/* STATE 2: SCATTER MODE */}
            <AnimatePresence>
              {viewMode === 'scatter' && (
                <motion.div 
                  initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0, transition: { duration: 0.1 } }}
                  className="absolute inset-0 flex items-center justify-center pointer-events-none"
                >
                  {activeLoc.photos.map((photo, i) => {
                    const offset = FIXED_OFFSETS[i % FIXED_OFFSETS.length];
                    const width = 140 + (i % 3) * 20; // 140-180px
                    return (
                      <motion.div
                        key={`scatter-${photo.id}`}
                        layoutId={`card-${photo.id}`}
                        initial={{ x: originX, y: originY, scale: 0.2, opacity: 0, rotate: 0 }}
                        animate={{ x: offset.x, y: offset.y, scale: 1, opacity: 1, rotate: offset.r }}
                        exit={{ x: originX, y: originY, scale: 0.2, opacity: 0, rotate: 0 }}
                        transition={{ type: 'spring', damping: 20, stiffness: 200, mass: 1, delay: i * 0.03 }}
                        className="absolute bg-white p-2.5 pb-10 shadow-[0_8px_24px_rgba(0,0,0,0.15)] rounded-sm pointer-events-auto cursor-grab active:cursor-grabbing"
                        style={{ width }}
                        drag
                        dragConstraints={{ top: -300, bottom: 300, left: -150, right: 150 }}
                        whileDrag={{ scale: 1.1, zIndex: 100, boxShadow: '0 20px 40px rgba(0,0,0,0.25)' }}
                        onClick={(e) => {
                          e.stopPropagation();
                          setCurrentIndex(i);
                          setViewMode('single');
                        }}
                      >
                        <motion.img layoutId={`img-${photo.id}`} src={photo.url} className="w-full aspect-square object-cover bg-gray-100" draggable={false} />
                      </motion.div>
                    )
                  })}
                </motion.div>
              )}
            </AnimatePresence>

            {/* STATE 3: SINGLE MODE */}
            <AnimatePresence>
              {viewMode === 'single' && (
                <motion.div 
                  initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0, transition: { duration: 0.2 } }}
                  className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none"
                >
                   {/* Main Card */}
                   <AnimatePresence mode="wait">
                     <motion.div
                       key={`single-${activeLoc.photos[currentIndex].id}`}
                       layoutId={`card-${activeLoc.photos[currentIndex].id}`}
                       initial={{ opacity: 0, scale: 0.9, x: 50 }}
                       animate={{ opacity: 1, scale: 1, x: 0 }}
                       exit={{ opacity: 0, scale: 0.9, x: -50 }}
                       transition={{ type: 'spring', damping: 25, stiffness: 300 }}
                       className="w-[320px] bg-white rounded-[12px] shadow-[0_16px_40px_rgba(0,0,0,0.2)] overflow-hidden pointer-events-auto"
                       onClick={(e) => e.stopPropagation()}
                       drag="x"
                       dragConstraints={{ left: 0, right: 0 }}
                       dragElastic={0.2}
                       onDragEnd={(e, { offset }) => {
                         const swipe = offset.x;
                         if (swipe < -60 && currentIndex < activeLoc.photos.length - 1) {
                           setCurrentIndex(currentIndex + 1);
                         } else if (swipe > 60 && currentIndex > 0) {
                           setCurrentIndex(currentIndex - 1);
                         }
                       }}
                     >
                       <motion.img 
                         layoutId={`img-${activeLoc.photos[currentIndex].id}`} 
                         src={activeLoc.photos[currentIndex].url} 
                         className="w-full aspect-[4/5] object-cover bg-gray-100" 
                         draggable={false} 
                       />
                       <div className="p-5 bg-white text-black">
                         <h3 className="font-bold text-[20px] mb-1.5">{activeLoc.name}</h3>
                         <p className="text-[14px] text-gray-500 mb-1">{activeLoc.photos[currentIndex].date}</p>
                         <p className="text-[12px] text-gray-400 font-mono">{activeLoc.photos[currentIndex].coordsString}</p>
                       </div>
                     </motion.div>
                   </AnimatePresence>

                   {/* Left/Right Navigation Arrows */}
                   <div className="absolute top-1/2 -translate-y-1/2 w-full px-4 flex justify-between pointer-events-none">
                      <button 
                        onClick={(e) => { e.stopPropagation(); if(currentIndex > 0) setCurrentIndex(currentIndex - 1); }}
                        className={cn("w-[44px] h-[44px] rounded-full bg-black/60 backdrop-blur-md flex items-center justify-center pointer-events-auto transition-opacity duration-300 active:scale-90", currentIndex === 0 ? 'opacity-0' : 'opacity-100')}
                      >
                        <ChevronLeft className="w-7 h-7 text-white -ml-0.5" />
                      </button>
                      <button 
                        onClick={(e) => { e.stopPropagation(); if(currentIndex < activeLoc.photos.length - 1) setCurrentIndex(currentIndex + 1); }}
                        className={cn("w-[44px] h-[44px] rounded-full bg-black/60 backdrop-blur-md flex items-center justify-center pointer-events-auto transition-opacity duration-300 active:scale-90", currentIndex === activeLoc.photos.length - 1 ? 'opacity-0' : 'opacity-100')}
                      >
                        <ChevronLeft className="w-7 h-7 text-white rotate-180 -mr-0.5" />
                      </button>
                   </div>

                   {/* Page Indicator */}
                   <div className="absolute bottom-[160px] px-4 py-1.5 rounded-full bg-black/60 backdrop-blur-md text-white text-[13px] font-medium tracking-widest pointer-events-none">
                      {currentIndex + 1} / {activeLoc.photos.length}
                   </div>
                </motion.div>
              )}
            </AnimatePresence>

          </motion.div>
        )}
      </AnimatePresence>

    </div>
  );
}

// --- NEW PHOTOS SCREEN (Date Timeline, Calendar & Magazine) ---
function PhotosScreen() {
  const [lightboxPhoto, setLightboxPhoto] = useState<any>(null);
  const [photoViewMode, setPhotoViewMode] = useState<'stack' | 'calendar' | 'magazine'>('magazine');

  return (
    <div className="relative w-full h-full bg-white text-black -mt-14 pt-14">
      
      {/* Segmented Control */}
      <div className="absolute top-14 left-0 right-0 z-40 bg-white/90 backdrop-blur-md pt-2 pb-3 flex justify-center border-b border-black/5">
        <div className="flex bg-[#EEEEEF] p-[3px] rounded-[16px]">
          {[
            { id: 'stack', label: '时间' },
            { id: 'calendar', label: '日历' },
            { id: 'magazine', label: '杂志' },
          ].map((mode) => (
            <button
              key={mode.id}
              onClick={() => setPhotoViewMode(mode.id as any)}
              className={cn(
                "px-5 py-1.5 rounded-[13px] text-[14px] font-semibold transition-all duration-200",
                photoViewMode === mode.id 
                  ? "bg-[#1C1C1E] text-white shadow-sm" 
                  : "text-[#8E8E93] hover:text-black"
              )}
            >
              {mode.label}
            </button>
          ))}
        </div>
      </div>

      {/* Scrollable Content */}
      <div className="h-full overflow-y-auto scrollbar-hide pt-[60px]">
        {photoViewMode === 'magazine' && (
          <div className="absolute inset-0 z-30 pt-[104px]">
             <MagazineView setLightboxPhoto={setLightboxPhoto} />
          </div>
        )}
        {photoViewMode === 'stack' && (
          <div className="pt-4 pb-56 px-5 flex flex-col gap-12">
            {timelineData.map((group) => (
              <div key={group.id} className="flex flex-col">
                {/* Header Group */}
                <div className="mb-4 pl-1 flex items-baseline gap-2">
                  {group.isSpecial ? (
                    <h2 className="text-[20px] font-bold text-[#FF6B35]">{group.title}</h2>
                  ) : (
                    <>
                      <h2 className="text-[20px] font-bold text-black">{group.title}</h2>
                      <span className="text-[#8E8E93] text-[20px] leading-none">·</span>
                      <span className="text-[18px] text-[#8E8E93]">{group.subtitle}</span>
                    </>
                  )}
                </div>
                
                {/* Polaroid Photo Row */}
                <div className="flex flex-row items-center pl-2">
                  {group.photos.map((photo, idx) => {
                    const offset = group.offsets[idx % group.offsets.length];
                    
                    return (
                      <motion.div
                        key={photo.id}
                        layoutId={`timeline-card-${photo.id}`}
                        initial={{ opacity: 0, y: 30, rotate: offset.r }}
                        whileInView={{ opacity: 1, y: offset.y, rotate: offset.r }}
                        viewport={{ once: true, margin: "0px 0px -50px 0px" }}
                        whileHover={{ scale: 1.05, rotate: 0, y: offset.y - 10, zIndex: 50 }}
                        whileTap={{ scale: 0.95 }}
                        onClick={() => setLightboxPhoto(photo)}
                        style={{ marginLeft: idx === 0 ? 0 : -35 }}
                        className="relative bg-white p-2 pb-6 shadow-[0_6px_16px_rgba(0,0,0,0.12)] rounded-[3px] w-[120px] flex-shrink-0 cursor-pointer origin-bottom"
                      >
                        <motion.img 
                          layoutId={`timeline-img-${photo.id}`} 
                          src={photo.url} 
                          className="w-full aspect-square object-cover bg-gray-100 rounded-sm" 
                          draggable={false} 
                        />
                      </motion.div>
                    );
                  })}
                </div>
              </div>
            ))}
          </div>
        )}

        {photoViewMode === 'calendar' && (
          <div className="pt-4 pb-56 px-4 flex flex-col gap-10">
            {/* June 2025 */}
            <div>
              <div className="flex justify-between items-center mb-4 pl-1 pr-1">
                <h2 className="text-[24px] font-bold text-black tracking-tight">June 2025</h2>
                <div className="flex gap-4">
                  <ChevronLeft className="w-5 h-5 text-black" />
                  <ChevronLeft className="w-5 h-5 text-black rotate-180" />
                </div>
              </div>
              
              <div className="grid grid-cols-7 gap-1 mb-2">
                {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map(d => (
                  <div key={d} className="text-center text-[13px] text-[#8E8E93] font-medium">{d}</div>
                ))}
              </div>
              
              <div className="grid grid-cols-7 gap-1">
                {calendarDays.map((c, i) => (
                  <div key={i} 
                    className={cn(
                      "aspect-square relative rounded-[8px] overflow-hidden",
                      c.photo ? "cursor-pointer active:scale-95 transition-transform" : "bg-[#F2F2F0]",
                      !c.inMonth && "opacity-40"
                    )}
                    onClick={() => { if (c.photo) setLightboxPhoto({ url: c.photo.url, date: `June ${c.day}, 2025`, id: c.photo.id }) }}
                  >
                     {c.photo ? (
                       <>
                         <img src={c.photo.url} className="w-full h-full object-cover" />
                         <div className="absolute inset-0 bg-gradient-to-b from-black/50 via-transparent to-transparent opacity-90" />
                         <span className="absolute top-[4px] left-[6px] text-white text-[14px] font-bold z-10 leading-none drop-shadow-md">{c.day}</span>
                         {c.photo.count > 1 && (
                           <div className="absolute top-[4px] right-[4px] bg-black/60 backdrop-blur-sm px-1.5 py-0.5 rounded-[4px] z-10">
                              <span className="text-white text-[10px] font-bold leading-none">{c.photo.count}</span>
                           </div>
                         )}
                       </>
                     ) : (
                       <span className={cn("absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-[15px] font-medium", c.inMonth ? "text-[#8E8E93]" : "text-[#D1D1D6]")}>
                         {c.day}
                       </span>
                     )}
                  </div>
                ))}
              </div>
            </div>

            {/* July 2025 (Faded scroll hint) */}
            <div className="opacity-40 pointer-events-none">
              <div className="flex justify-between items-center mb-4 pl-1 pr-1">
                <h2 className="text-[24px] font-bold text-black tracking-tight">July 2025</h2>
              </div>
              <div className="grid grid-cols-7 gap-1 mb-2">
                {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map(d => (
                  <div key={d} className="text-center text-[13px] text-[#8E8E93] font-medium">{d}</div>
                ))}
              </div>
              <div className="grid grid-cols-7 gap-1">
                {[{d: 29}, {d: 30}].map((c, i) => (
                  <div key={`lead-${i}`} className="aspect-square relative rounded-[8px] overflow-hidden bg-[#F2F2F0] opacity-50">
                    <span className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-[15px] font-medium text-[#D1D1D6]">{c.d}</span>
                  </div>
                ))}
                {Array.from({length: 31}, (_, i) => {
                  const d = i + 1;
                  return (
                    <div key={i} className="aspect-square relative rounded-[8px] overflow-hidden bg-[#F2F2F0]">
                      <span className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-[15px] font-medium text-[#8E8E93]">
                         {d}
                       </span>
                    </div>
                  )
                })}
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Floating "Listening" Card */}
      {photoViewMode !== 'magazine' && (
        <div className="absolute bottom-[96px] left-1/2 -translate-x-1/2 w-[340px] bg-[#F7F7F5] p-4 rounded-[20px] shadow-[0_8px_24px_rgba(0,0,0,0.08)] z-30 pointer-events-auto">
           <div className="flex items-center gap-2 mb-1">
              <div className="w-2.5 h-2.5 rounded-full bg-[#FF6B35]" />
              <span className="text-[18px] font-bold text-black tracking-tight leading-none">Listening</span>
           </div>
           <p className="text-[15px] text-[#8E8E93] mb-4">Speak freely, we'll make sense of it after.</p>
           <div className="flex justify-between items-center">
              <div className="flex items-center gap-2 text-black font-medium">
                 <Activity className="w-5 h-5 text-[#8E8E93]" />
                 <span>1:32</span>
              </div>
              <div className="flex gap-2">
                 <button className="w-10 h-10 bg-white rounded-full flex items-center justify-center shadow-sm text-black active:scale-95 transition-transform">
                    <Pause className="w-4 h-4 fill-current" />
                 </button>
                 <button className="h-10 px-4 bg-white rounded-full flex items-center justify-center gap-1.5 shadow-sm text-black font-semibold text-[14px] active:scale-95 transition-transform">
                    <Square className="w-3.5 h-3.5 fill-current" />
                    Stop
                 </button>
              </div>
           </div>
        </div>
      )}

      {/* Lightbox Overlay */}
      <AnimatePresence>
        {lightboxPhoto && (
           <motion.div
             initial={{ opacity: 0 }}
             animate={{ opacity: 1 }}
             exit={{ opacity: 0 }}
             className="absolute inset-0 z-[100] bg-black/60 backdrop-blur-md flex flex-col items-center justify-center pointer-events-auto"
             onClick={() => setLightboxPhoto(null)}
           >
             <motion.div
               layoutId={`timeline-card-${lightboxPhoto.id}`}
               className="w-[320px] bg-white rounded-[12px] shadow-2xl overflow-hidden p-3 pb-8 relative"
               onClick={(e) => e.stopPropagation()}
             >
               <motion.img
                 layoutId={`timeline-img-${lightboxPhoto.id}`}
                 src={lightboxPhoto.url}
                 className="w-full aspect-square object-cover bg-gray-100 rounded-[8px]"
                 draggable={false}
               />
               <div className="absolute bottom-2 left-0 right-0 text-center">
                 <p className="text-[13px] text-gray-500 font-medium">{lightboxPhoto.date}</p>
               </div>
             </motion.div>
           </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

function MagazineView({ setLightboxPhoto }: { setLightboxPhoto: (p: any) => void }) {
  const [viewState, setViewState] = useState<'carousel' | 'book'>('carousel');
  const [activeYearIndex, setActiveYearIndex] = useState(3);
  const [activeMonthIndex, setActiveMonthIndex] = useState(4); // May

  return (
    <div className="absolute inset-0 bg-[#FAFAF8] overflow-hidden rounded-[55px]">
      {/* Radial glow */}
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_40%,_rgba(240,210,230,0.5)_0%,_rgba(250,250,248,0)_60%)] pointer-events-none" />
      
      <AnimatePresence mode="wait">
        {viewState === 'carousel' ? (
          <MagazineCarousel key="carousel" 
             activeYearIndex={activeYearIndex} 
             setActiveYearIndex={setActiveYearIndex} 
             onOpen={() => setViewState('book')} 
          />
        ) : (
          <MagazineBook key="book" 
             activeYearIndex={activeYearIndex} 
             activeMonthIndex={activeMonthIndex}
             setActiveMonthIndex={setActiveMonthIndex}
             onClose={() => setViewState('carousel')} 
             setLightboxPhoto={setLightboxPhoto}
          />
        )}
      </AnimatePresence>
    </div>
  )
}

function MagazineCarousel({ activeYearIndex, setActiveYearIndex, onOpen }: any) {
  return (
    <motion.div 
      initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
      className="absolute inset-0 flex items-center justify-center pt-10"
      drag="y"
      dragConstraints={{ top: 0, bottom: 0 }}
      onDragEnd={(e, { offset }) => {
        if (offset.y < -50 && activeYearIndex < yearsData.length - 1) setActiveYearIndex(activeYearIndex + 1);
        if (offset.y > 50 && activeYearIndex > 0) setActiveYearIndex(activeYearIndex - 1);
      }}
    >
       {/* Left side year list */}
       <div className="absolute left-6 top-1/2 -translate-y-1/2 flex flex-col gap-6 font-bold z-10 pointer-events-none">
         {yearsData.map((y, i) => (
            <div key={y.year} className="flex items-center gap-2 transition-all duration-300" style={{ opacity: activeYearIndex === i ? 1 : 0.3, transform: activeYearIndex === i ? 'scale(1.2)' : 'scale(1)', transformOrigin: 'left center' }}>
              {activeYearIndex === i && <span className="text-[10px] text-black">▶</span>}
              <span className="text-black">{y.year}</span>
            </div>
         ))}
       </div>

       {/* Top-right & Bottom-right icons */}
       <div className="absolute top-20 right-6 w-10 h-10 rounded-full bg-white shadow-[0_4px_12px_rgba(0,0,0,0.08)] flex items-center justify-center z-10">
         <User className="w-5 h-5 text-black" />
       </div>
       <div className="absolute bottom-[120px] right-6 w-12 h-12 rounded-full bg-black flex items-center justify-center z-10 shadow-lg cursor-pointer">
         <Plus className="w-6 h-6 text-white" />
       </div>

       {/* Cards Stack */}
       <div className="relative w-[220px] h-[300px] ml-16">
         {yearsData.map((y, i) => {
           const dist = i - activeYearIndex;
           const isActive = dist === 0;
           const yOffset = dist * 160;
           const xOffset = dist * 30; // diagonal tilt
           const rotate = dist * 8;
           const scale = isActive ? 1 : 0.85;
           const zIndex = 10 - Math.abs(dist);

           return (
             <motion.div
               key={y.year}
               animate={{ y: yOffset, x: xOffset, rotate, scale, zIndex }}
               transition={{ type: 'spring', damping: 20, stiffness: 200 }}
               className="absolute inset-0 cursor-pointer"
               onClick={() => {
                 if (isActive) onOpen();
                 else setActiveYearIndex(i);
               }}
             >
                {/* Book Edges */}
                <div className="absolute -right-2 -bottom-2 inset-0 rounded-[20px] border border-black/5" style={{ backgroundColor: y.color, opacity: 0.8 }} />
                <div className="absolute -right-1 -bottom-1 inset-0 rounded-[20px] border border-black/5" style={{ backgroundColor: y.color, opacity: 0.9 }} />
                
                {/* Cover */}
                <div className="absolute inset-0 rounded-[20px] overflow-hidden bg-white shadow-xl border border-black/10">
                  <img src={y.cover} className="w-full h-full object-cover" draggable={false} />
                  <div className="absolute inset-0 bg-black/20 pointer-events-none" />
                  <div className="absolute top-6 left-6 text-white text-[44px] font-bold leading-none tracking-tighter mix-blend-overlay opacity-90 pointer-events-none">
                    {y.year}
                  </div>
                </div>
             </motion.div>
           )
         })}
       </div>
    </motion.div>
  )
}

function MagazineBook({ activeYearIndex, activeMonthIndex, setActiveMonthIndex, onClose, setLightboxPhoto }: any) {
  const year = yearsData[activeYearIndex].year;
  const monthDetails = [
    { m: 1, cjk: '一月', num: '01', color: '#D26B6B' },
    { m: 2, cjk: '二月', num: '02', color: '#DAB279' },
    { m: 3, cjk: '三月', num: '03', color: '#8CB39E' },
    { m: 4, cjk: '四月', num: '04', color: '#7AA8A1' },
    { m: 5, cjk: '五月', num: '05', color: '#8FA5D1' },
    { m: 6, cjk: '六月', num: '06', color: '#A592C4' },
    { m: 7, cjk: '七月', num: '07', color: '#D3889B' },
    { m: 8, cjk: '八月', num: '08', color: '#E59573' },
    { m: 9, cjk: '九月', num: '09', color: '#C4A77D' },
    { m: 10, cjk: '十月', num: '10', color: '#829C8E' },
    { m: 11, cjk: '十一月', num: '11', color: '#729B9B' },
    { m: 12, cjk: '十二月', num: '12', color: '#9F8C8C' }
  ];

  return (
    <motion.div 
      initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.9 }}
      className="absolute inset-0 z-50 flex flex-col pt-14 pb-24 pointer-events-none bg-gradient-to-br from-[#1A1A14] to-[#2A2C29]"
    >
      {/* Top Bar */}
      <div className="flex justify-between items-center px-5 py-2 pointer-events-auto z-10">
        <button onClick={onClose} className="w-10 h-10 rounded-full bg-white/10 backdrop-blur-md shadow-[0_2px_8px_rgba(0,0,0,0.1)] flex items-center justify-center active:scale-95 transition-transform text-white">
          <ChevronLeft className="w-6 h-6 -ml-0.5" />
        </button>
      </div>

      {/* Book Slider */}
      <div className="flex-1 relative flex items-center justify-center w-full mt-[-20px] pointer-events-auto overflow-hidden" style={{ perspective: '1200px' }}>
        {/* Left Arrow */}
        <button 
          onClick={() => activeMonthIndex > 0 && setActiveMonthIndex(activeMonthIndex - 1)}
          className="absolute left-3 top-1/2 -translate-y-1/2 z-[60] w-11 h-11 flex items-center justify-center bg-black/30 rounded-full text-white backdrop-blur-md disabled:opacity-0 transition-all duration-300 active:scale-90"
          disabled={activeMonthIndex === 0}
        >
          <ChevronLeft className="w-7 h-7 -ml-0.5 opacity-90" />
        </button>

        {/* Right Arrow */}
        <button 
          onClick={() => activeMonthIndex < 11 && setActiveMonthIndex(activeMonthIndex + 1)}
          className="absolute right-3 top-1/2 -translate-y-1/2 z-[60] w-11 h-11 flex items-center justify-center bg-black/30 rounded-full text-white backdrop-blur-md disabled:opacity-0 transition-all duration-300 active:scale-90"
          disabled={activeMonthIndex === 11}
        >
          <ChevronLeft className="w-7 h-7 rotate-180 opacity-90" />
        </button>

        <motion.div
           drag="x"
           dragConstraints={{ left: 0, right: 0 }}
           onDragEnd={(e, { offset }) => {
             if (offset.x < -60 && activeMonthIndex < 11) setActiveMonthIndex(activeMonthIndex + 1);
             if (offset.x > 60 && activeMonthIndex > 0) setActiveMonthIndex(activeMonthIndex - 1);
           }}
           className="absolute inset-0 flex items-center justify-center"
           style={{ transformStyle: 'preserve-3d' }}
        >
          {monthDetails.map((month, i) => {
             const dist = i - activeMonthIndex;
             if (Math.abs(dist) > 3) return null;

             const xOffset = dist * 140; 
             const rotateY = dist * -20;
             const zOffset = -Math.abs(dist) * 120;
             const scale = 1;
             const opacity = 1 - Math.abs(dist) * 0.15;

             return (
               <motion.div 
                 key={month.m}
                 animate={{ x: xOffset, z: zOffset, rotateY, scale, opacity, zIndex: 10 - Math.abs(dist) }}
                 transition={{ type: 'spring', damping: 25, stiffness: 220 }}
                 className="absolute w-[330px] h-[480px] bg-white rounded-[16px] shadow-[0_16px_40px_rgba(0,0,0,0.4),_0_0_0_1px_rgba(255,255,255,0.1)] overflow-hidden flex flex-col pointer-events-auto"
                 style={{ transformOrigin: 'center center' }}
               >
                 {/* Spine curl */}
                 <div className="absolute left-0 top-0 bottom-0 w-8 bg-gradient-to-r from-black/[0.08] to-transparent pointer-events-none z-20" />

                 {/* Top Content */}
                 <div className="pt-4 pb-2 px-4 relative z-10 flex flex-col bg-[#FDFDFD]">
                    {/* Small month strip */}
                    <div className="flex justify-between items-center text-[10px] text-gray-300 font-bold mb-4 px-1">
                      {monthDetails.map(m => (
                        <span key={m.m} style={{ color: m.m === month.m ? month.color : undefined, opacity: m.m === month.m ? 1 : 0.6 }}>
                          {m.cjk.replace('月', '')}
                        </span>
                      ))}
                    </div>

                    <div className="flex justify-between items-end mb-2">
                       <div className="flex items-baseline gap-2">
                         <h3 className="text-[34px] font-bold leading-none tracking-tight" style={{ color: month.color }}>{month.cjk}</h3>
                         <span className="text-[14px] font-bold text-gray-400">{year}</span>
                       </div>
                       <span className="text-[48px] font-black leading-none -mb-1" style={{ color: month.color, opacity: 0.15 }}>{month.num}</span>
                    </div>
                 </div>

                 {/* Weekday Row */}
                 <div className="grid grid-cols-7 py-1.5" style={{ backgroundColor: month.color + '15' }}>
                   {['一', '二', '三', '四', '五', '六', '日'].map(d => (
                     <div key={d} className="text-center text-[12px] font-bold" style={{ color: month.color }}>{d}</div>
                   ))}
                 </div>

                 {/* Calendar Grid mosaic */}
                 <div className="flex-1 bg-gray-100 p-[1px] grid grid-cols-7 gap-[1px] content-start">
                   {Array.from({length: (month.m * 2) % 7}).map((_, idx) => (
                     <div key={`empty-${idx}`} className="aspect-square bg-[#F5F5F5]" />
                   ))}
                   {Array.from({length: 30}).map((_, idx) => {
                     const day = idx + 1;
                     const hasPhoto = day % 4 !== 0 && day !== 3 && day !== 14; 
                     return (
                       <div 
                         key={day} 
                         className={cn("aspect-square relative overflow-hidden", hasPhoto ? "bg-gray-300 cursor-pointer active:scale-95 transition-transform" : "bg-[#FDFDFD]")}
                         onClick={() => {
                           if (hasPhoto) {
                             setLightboxPhoto({ url: `https://picsum.photos/seed/${year}${month.m}${day}/400/400`, date: `${year}年${month.cjk}${day}日`, id: `flip-${year}-${month.m}-${day}` });
                           }
                         }}
                       >
                         {hasPhoto ? (
                           <>
                             <img src={`https://picsum.photos/seed/${year}${month.m}${day}/400/400`} className="w-full h-full object-cover" draggable={false} />
                             <div className="absolute inset-0 bg-black/10 pointer-events-none" />
                             <span className="absolute top-0.5 right-1 text-white text-[10px] font-bold z-10 drop-shadow-[0_1px_2px_rgba(0,0,0,0.8)] pointer-events-none">{day}</span>
                           </>
                         ) : (
                           <span className="absolute top-1 left-1.5 text-[11px] font-medium text-[#C8C8C8]">{day}</span>
                         )}
                       </div>
                     )
                   })}
                 </div>
               </motion.div>
             )
          })}
        </motion.div>
      </div>
    </motion.div>
  )
}

function AlbumsScreen() {
  return <div className="w-full h-full bg-[#F5F4F1] flex items-center justify-center text-gray-400">Albums Tab Content</div>;
}