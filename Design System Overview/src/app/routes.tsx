import { createBrowserRouter } from "react-router";
import Root from "./components/Root";
import MapView from "./components/MapView";
import AlbumView from "./components/AlbumView";
import MemoryView from "./components/MemoryView";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: Root,
    children: [
      { index: true, Component: MapView },
      { path: "album", Component: AlbumView },
      { path: "memory", Component: MemoryView },
    ],
  },
]);
