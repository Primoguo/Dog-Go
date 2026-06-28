import SwiftUI

extension LifeEventRecord {
    var visualPose: DogVisualPose {
        switch definitionID {
        case "first_short_leave", "hallway_steps": .standTurn
        case "hidden_toy_01", "paper_bag", "toy_returned_to_rug": .playBow
        case "sun_patch", "better_sleep_spot", "straighten_blanket_01": .lieRest
        default: .sitWindow
        }
    }

    var emotionTitle: String {
        switch emotion {
        case "happy": "心情很好"
        case "excited": "有点兴奋"
        case "low": "想安静一下"
        default: "很平静"
        }
    }

    var emotionSymbolName: String {
        switch emotion {
        case "happy": "sun.max.fill"
        case "excited": "sparkles"
        case "low": "cloud.fill"
        default: "leaf.fill"
        }
    }

    var visualTraceTitle: String? {
        guard let visualTraceID else { return nil }
        return switch visualTraceID {
        case "mat_shifted_near_door": "门边的垫子被踩歪了一点"
        case "chosen_resting_spot": "垫子被拖到了更靠近你的地方"
        case "nose_mark_on_window": "玻璃上留着一点鼻尖的雾印"
        case "toy_tail_under_cushion": "垫子下面露出一小截玩具"
        case "warm_spot_on_rug": "地毯上还留着一块暖暖的阳光"
        case "ears_toward_door": "它的耳朵仍朝着门口"
        case "blanket_new_fold": "毯子多了一个新的折角"
        case "paper_bag_crumpled": "纸袋的一边被轻轻压皱了"
        case "small_water_ripple": "水碗里还有一圈细小波纹"
        case "pillow_dented": "靠窗的软垫留下一个浅浅的窝"
        case "small_object_by_wall": "小东西被整齐地推到了墙边"
        case "feather_near_window": "窗边多出了一根很轻的羽毛"
        case "toy_returned_to_rug": "玩具重新出现在地毯上"
        case "dog_resting_on_new_fold": "它正靠着昨天整理的折角"
        default: "房间里留下了一点生活过的痕迹"
        }
    }
}

struct EventVisualThumbnail: View {
    let event: LifeEventRecord
    let dogName: String

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image("SceneHomeBase")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                if let trace = HomeSceneTrace.resolve(visualTraceID: event.visualTraceID) {
                    Image(trace.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width * min(trace.width * 1.5, 0.32))
                        .position(x: proxy.size.width * trace.x, y: proxy.size.height * trace.y)
                }

                DogAnimationPlayerView(
                    pose: event.visualPose,
                    accessibilityLabel: "\(dogName)的生活片段画面"
                )
                .frame(width: proxy.size.width * 0.72, height: proxy.size.height * 0.82)
                .position(x: proxy.size.width * 0.50, y: proxy.size.height * 0.58)

                LinearGradient(
                    colors: [.clear, DogGoTheme.Colors.ink.opacity(0.28)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(dogName)的生活片段：\(event.emotionTitle)")
    }
}
