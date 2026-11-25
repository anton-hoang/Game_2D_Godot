# Chronicles of Windferry — 2.5D HD-2D Action RPG (Godot 4.x)

Project game hành động 2.5D phong cách **HD-2D (Octopath Traveler / Windferry Hamlet)**: nhân vật, quái vật và cây cối là **Sprite 2D Pixel Art** (`AnimatedSprite3D` / `Sprite3D`, Billboard, có đổ bóng thật) đứng trong **thế giới 3D có ánh sáng ấm, nước phản chiếu và hậu kỳ Tilt-Shift DOF + Bloom + Fog + SSAO + Vignette**.

---

## 1. Cách mở và chạy ngay (Godot 4.x)

1. Mở **Godot Engine 4.x** (Project hiện đang cấu hình sẵn cho Godot 4.x Forward+).
2. Nhấn **Import** -> Chọn file `project.godot` trong thư mục `d:\Game_2D\2d-rpg`.
3. Nhấn phím **`F5`** (hoặc nút **Play** ở góc trên bên phải Editor) để chạy ngay scene chính `res://scenes/stages/main_game.tscn`.
   - Toàn bộ sprite pixel art (Lữ khách, 4 loại quái, Boss, cây cổ thụ, bụi hoa, vật phẩm) và hiệu ứng âm thanh (SFX/BGM) được sinh tự động bằng code (`PixelArtGenerator` & `AudioManager`) nên **chạy được ngay lập tức 100% không cần tải thêm asset ngoài**.

---

## 2. Điều khiển (Bàn phím & Tay cầm)

| Hành động | Bàn phím | Tay cầm (Gamepad) | Mô tả |
| :--- | :--- | :--- | :--- |
| **Di chuyển 8 hướng** | `W A S D` hoặc Phím mũi tên | Cần gạt trái (Left Stick) | Di chuyển trên mặt phẳng XZ |
| **Tấn công thường** | `J` / `Z` / `Space` | Nút `X` (Xbox) / `Vuông` (PS) | Combo 3 đòn liên tiếp (đòn 3 chí mạng + đẩy lùi mạnh) |
| **Kỹ năng đặc biệt** | `K` / `X` | Nút `Y` (Xbox) / `Tam giác` (PS) | Kiếm Khí Xung Kích 360° (Tốn 35 Năng lượng) |
| **Né (Dash)** | `L` / `C` / `Shift` | Nút `A` (Xbox) / `X` (PS) | Lướt nhanh có thời gian hồi & bất tử ngắn (i-frame) |
| **Tạm dừng** | `ESC` / `P` | Nút `Start` | Mở menu Tạm dừng |
| **Đổi nhanh ánh sáng HD-2D** | Phím `1` / `2` / `3` / `R` / `4` | — | `1`: Hoàng hôn \| `2`: Đêm xanh \| `3`: Màn Đêm Sâu \| `R`: Đêm mưa \| `4`: Nguyệt thực |
| **Bật/Tắt Tilt-Shift DOF** | Phím `G` / `H` | — | `G`: Bật/tắt làm mờ DOF \| `H`: Ẩn/hiện HUD để chụp ảnh |

---

## 3. Cấu trúc thư mục Project

```text
res://
├── project.godot
├── scenes/
│   ├── player/
│   │   └── player.tscn                 # Scene Nhân vật chính (CharacterBody3D)
│   ├── enemies/
│   │   └── enemy_base.tscn             # Scene Quái vật & Boss (State Machine AI)
│   ├── stages/
│   │   └── main_game.tscn              # Scene chính kết nối Thế giới 3D HD-2D & UI
│   └── ui/
│       └── game_ui.tscn                # Giao diện HUD, Menu, Chọn màn, Nâng cấp, Kết quả
├── scripts/
│   ├── autoload/
│   │   ├── game_manager.gd             # Quản lý vòng lặp màn, điểm, hạng S/A/B/C, Hit-stop, InputMap
│   │   ├── audio_manager.gd            # Quản lý SFX & BGM (tự sinh âm thanh synth + hỗ trợ file thật)
│   │   └── save_manager.gd             # Lưu/Tải tiến trình bằng ConfigFile (user://save_data.cfg)
│   ├── player/
│   │   ├── player_controller.gd        # Điều khiển 8 hướng, Combo 3 đòn, Kỹ năng K, Dash L
│   │   └── camera_rig_3d.gd            # Camera nghiêng 33°, FOV 28°, Lerp mượt, Shake & Tilt-Shift DOF
│   ├── enemies/
│   │   ├── enemy_base.gd               # AI State Machine (Idle, Chase, Attack, Hurt, Die) & Boss 3 Pha
│   │   └── enemy_projectile_3d.gd      # Đạn phép phát sáng của quái Ranged & Boss
│   ├── stages/
│   │   ├── hd2d_environment_builder.gd # Dựng làng cổ HD-2D: cầu đá, suối nước, nhà gỗ, đèn lồng, mưa
│   │   ├── stage_manager.gd            # Wave Spawner, kiểm tra qua đợt/qua màn, rơi vật phẩm
│   │   ├── wave_portal_3d.gd           # Cổng ánh sáng mở sang đợt tiếp theo
│   │   ├── pickup_3d.gd                # Vật phẩm rơi: Máu (HP), Năng lượng (MP), Vàng
│   │   └── main_game.gd                # Điều phối tổng thể
│   ├── resources/
│   │   ├── enemy_stats.gd              # Class Resource EnemyStats
│   │   ├── stage_data.gd               # Class Resource StageData
│   │   └── stage_database.gd           # Tải và cân bằng chỉ số 5 màn chơi + 5 loại quái
│   ├── ui/
│   │   └── game_ui_controller.gd       # HUD, Thanh máu Boss, Menu, Cửa hàng nâng cấp, Xếp hạng
│   └── vfx/
│       ├── pixel_art_generator.gd      # Sinh SpriteFrames Pixel Art tự động cho Player, Quái, Cây, Icon
│       └── damage_number_3d.gd         # Số sát thương bay lên (Label3D Billboard)
├── resources/
│   ├── enemy_stats/                    # 5 file Resource (.tres): melee, ranged, charger, tank, boss
│   └── stage_data/                     # 5 file Resource (.tres): stage_1 đến stage_5
└── assets/
    ├── sprites/                        # Nơi đặt spritesheet PNG thật khi thay thế placeholder
    ├── audio/                          # Nơi đặt file âm thanh .wav/.ogg thật
    └── shaders/
        ├── water_hd2d.gdshader         # Shader mặt nước phản chiếu ánh đèn lồng lấp lánh
        └── vignette.gdshader           # Shader Vignette làm tối 4 góc màn hình
```

---

## 4. Hướng dẫn thay Asset thật (Sprite & Audio)

1. **Thay Sprite Nhân vật chính (`Player`)**:
   - Mở `res://scenes/player/player.tscn`, chọn node `Player`.
   - Trong thanh **Inspector**, kéo file `SpriteFrames` của bạn vào ô **`Custom Sprite Frames`** (với các animation: `idle`, `run`, `dash`, `attack_1`, `attack_2`, `attack_3`, `special`, `hurt`).
2. **Thay Sprite Quái vật & Boss (`EnemyStats`)**:
   - Mở bất kỳ file nào trong `res://resources/enemy_stats/` (`melee.tres`, `ranged.tres`, `charger.tres`, `tank.tres`, `boss.tres`).
   - Gán `SpriteFrames` thật vào thuộc tính **`Custom Sprite Frames`** trên Inspector (các animation: `idle`, `move`, `attack`, `hurt`, `die`).
3. **Thay Âm thanh thật (`AudioManager`)**:
   - Bỏ file `.wav` hoặc `.ogg` vào `res://assets/audio/`.
   - Gán vào dictionary `custom_streams` trong `res://scripts/autoload/audio_manager.gd` (các khóa: `"slash"`, `"special"`, `"hit"`, `"hurt"`, `"dash"`, `"pickup"`, `"gate"`, `"victory"`, `"boss_roar"`).
4. **Thêm màn chơi mới (`StageData`)**:
   - Nhân bản một file trong `res://resources/stage_data/stage_1.tres`, chỉnh danh sách `waves`, `time_of_day` (`golden_hour`, `blue_night`, `rainy_night`, `crimson_eclipse`) và `target_clear_time`.
