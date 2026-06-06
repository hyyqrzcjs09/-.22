// 用户画像 + 匹配算法
// 思路借鉴 TrendRadar 的「关键词加权打分」：把「新闻 vs 关键词」换成「用户 vs 用户」。
// 照片 → 兴趣标签 → 带权重的画像向量 → 两个向量的余弦相似度 = 匹配度。

export interface Interest {
  key: string;
  label: string;
  emoji: string;
  color: string;
}

// 兴趣标签字典
export const INTERESTS: Record<string, Interest> = {
  travel: { key: "travel", label: "旅行", emoji: "🎒", color: "#0A84FF" },
  food: { key: "food", label: "美食", emoji: "🍳", color: "#FF9F0A" },
  pet: { key: "pet", label: "萌宠", emoji: "🐾", color: "#FF6B6B" },
  music: { key: "music", label: "音乐", emoji: "🎵", color: "#BF5AF2" },
  photo: { key: "photo", label: "摄影", emoji: "📷", color: "#30B0C7" },
  coffee: { key: "coffee", label: "咖啡", emoji: "☕️", color: "#A2845E" },
  nature: { key: "nature", label: "自然", emoji: "🌿", color: "#34C759" },
  city: { key: "city", label: "城市", emoji: "🏙️", color: "#5E5CE6" },
  night: { key: "night", label: "夜生活", emoji: "🌃", color: "#FF375F" },
};

// 相册名 → 兴趣标签（AI「读取照片」的简化版：用现有相册聚合，未来可换真模型逐张打标）
const ALBUM_TO_TAGS: Record<string, string[]> = {
  英国: ["travel", "city"],
  Picslog: ["photo", "city"],
  做饭: ["food"],
  "兔子🐶": ["pet"],
  "G.E.M": ["music"],
};

export interface Profile {
  weights: Record<string, number>; // 标签 -> 0~1 权重
  topTags: string[];               // 按权重降序的标签 key
  persona: string;                 // AI 风格人设一句话
}

// 把一组 {标签: 原始计数} 归一化成 0~1，并生成画像
export function buildProfile(rawWeights: Record<string, number>): Profile {
  const max = Math.max(1, ...Object.values(rawWeights));
  const weights: Record<string, number> = {};
  for (const [k, v] of Object.entries(rawWeights)) {
    weights[k] = +(v / max).toFixed(3);
  }
  const topTags = Object.keys(weights).sort((a, b) => weights[b] - weights[a]);
  return { weights, topTags, persona: generatePersona(topTags) };
}

// 从相册（名称 + 照片数）聚合「我」的画像
export function buildMyProfile(albums: { name: string; count: number }[]): Profile {
  const raw: Record<string, number> = {};
  for (const a of albums) {
    const tags = ALBUM_TO_TAGS[a.name];
    if (!tags) continue;
    for (const t of tags) raw[t] = (raw[t] || 0) + a.count;
  }
  return buildProfile(raw);
}

// 称号映射：用 top1 标签生成一个人设称号
const TITLES: Record<string, string> = {
  travel: "城市漫游者",
  food: "美食猎人",
  pet: "资深铲屎官",
  music: "旋律捕手",
  photo: "光影记录者",
  coffee: "咖啡因依赖者",
  nature: "自然收集者",
  city: "都市夜行人",
  night: "夜行动物",
};

export function generatePersona(topTags: string[]): string {
  if (!topTags.length) return "神秘的灵魂";
  const t1 = INTERESTS[topTags[0]];
  const title = TITLES[topTags[0]] || `${t1.label}爱好者`;
  if (topTags[1]) {
    const t2 = INTERESTS[topTags[1]];
    return `${title} · 也爱${t2.label}`;
  }
  return title;
}

// 余弦相似度 → 匹配度百分比（0~100，取整）
export function matchScore(a: Profile, b: Profile): number {
  const keys = new Set([...Object.keys(a.weights), ...Object.keys(b.weights)]);
  let dot = 0,
    na = 0,
    nb = 0;
  for (const k of keys) {
    const x = a.weights[k] || 0;
    const y = b.weights[k] || 0;
    dot += x * y;
    na += x * x;
    nb += y * y;
  }
  if (na === 0 || nb === 0) return 0;
  return Math.round((dot / (Math.sqrt(na) * Math.sqrt(nb))) * 100);
}

// 两人共同的高权重标签（按两边权重之和降序）
export function commonTags(a: Profile, b: Profile, limit = 4): string[] {
  return Object.keys(a.weights)
    .filter((k) => b.weights[k] !== undefined)
    .sort((x, y) => (b.weights[y] + a.weights[y]) - (b.weights[x] + a.weights[x]))
    .slice(0, limit);
}

// —— 时空环：照片在「地点 + 时间」上的叠合 ——

// 南京主城区的地点（与漫游地图标记一致，含经纬度）
export const LOCATIONS: Record<string, { name: string; photo: string; lngLat: [number, number] }> = {
  xuanwu: { name: "玄武湖", photo: "https://images.unsplash.com/photo-1501786223405-6d024d7c3b8d?q=80&w=200", lngLat: [118.797, 32.076] },
  xinjiekou: { name: "新街口", photo: "https://images.unsplash.com/photo-1449824913935-59a10b8d2000?q=80&w=200", lngLat: [118.778, 32.0419] },
  gulou: { name: "鼓楼", photo: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?q=80&w=200", lngLat: [118.777, 32.066] },
  fuzimiao: { name: "夫子庙", photo: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=200", lngLat: [118.788, 32.022] },
  minggugong: { name: "明故宫", photo: "https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?q=80&w=200", lngLat: [118.809, 32.044] },
};

// 一条足迹 = 在某地点、某月份拍过照
export interface Footprint {
  place: string;
  month: number; // 1~12
}

// 「我」的南京足迹（来自现有照片的地点 + 时间）
export const MY_FOOTPRINTS: Footprint[] = [
  { place: "xuanwu", month: 5 },
  { place: "xinjiekou", month: 6 },
  { place: "gulou", month: 4 },
  { place: "fuzimiao", month: 6 },
  { place: "minggugong", month: 5 },
];

export interface MockUser {
  id: string;
  name: string;
  avatar: string;
  profile: Profile;
  footprints: Footprint[];
}

// 预埋的「对方」用户，性格各异，碰一碰会算出高/中/低不同匹配度
export const MOCK_USERS: MockUser[] = [
  {
    id: "u1",
    name: "林一",
    avatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200",
    profile: buildProfile({ travel: 9, photo: 8, coffee: 5, city: 6, food: 3 }),
    // 和「我」重合多、时间也相近（多次擦肩）
    footprints: [
      { place: "xuanwu", month: 3 },
      { place: "xinjiekou", month: 6 },
      { place: "minggugong", month: 5 },
    ],
  },
  {
    id: "u2",
    name: "阿楠",
    avatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200",
    profile: buildProfile({ food: 9, pet: 7, travel: 2, coffee: 4 }),
    footprints: [
      { place: "fuzimiao", month: 6 },
      { place: "xinjiekou", month: 5 },
      { place: "gulou", month: 4 },
    ],
  },
  {
    id: "u3",
    name: "Coco",
    avatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=200",
    profile: buildProfile({ music: 9, night: 8, travel: 1 }),
    // 去过的地方少、时间也错得远
    footprints: [
      { place: "gulou", month: 7 },
      { place: "xuanwu", month: 1 },
    ],
  },
];

export interface SpacetimeMatch {
  place: string;
  name: string;
  photo: string;
  myMonth: number;
  otherMonth: number;
  gap: number; // 月份差
  brushed: boolean; // 时间也接近 = 擦肩而过
}

// 时空环：求两人足迹的共同地点，并算时间接近度（按时间差升序，越接近越靠前）
export function computeSpacetimeRing(
  mine: Footprint[],
  theirs: Footprint[]
): SpacetimeMatch[] {
  const out: SpacetimeMatch[] = [];
  for (const m of mine) {
    const t = theirs.find((x) => x.place === m.place);
    if (!t) continue;
    const gap = Math.abs(m.month - t.month);
    out.push({
      place: m.place,
      name: LOCATIONS[m.place]?.name ?? m.place,
      photo: LOCATIONS[m.place]?.photo ?? "",
      myMonth: m.month,
      otherMonth: t.month,
      gap,
      brushed: gap <= 1,
    });
  }
  return out.sort((a, b) => a.gap - b.gap);
}
