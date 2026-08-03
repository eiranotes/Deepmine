import type { Metadata } from "next";
import { MinePrototype } from "./MinePrototype";

export const metadata: Metadata = {
  title: "DeepMine — 플레이어블 웹 데모",
  description: "암반을 직접 깨고 장비를 강화하며 자동 채굴을 여는 DeepMine 웹 데모",
};

export default function Home() {
  return <MinePrototype />;
}
