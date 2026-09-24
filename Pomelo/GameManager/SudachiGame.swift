//
//  PomeloGame.swift
//  Pomelo
//
//  Created by Stossy11 on 
//  Copyright © 2024 Stossy11. All rights reserved.13/7/2024.
//

import Foundation
import SwiftUI

struct PomeloGame : Comparable, Hashable, Identifiable {
    var id = UUID()
    
    let programid: Int
    let ishomebrew: Bool
    let developer: String
    let fileURL: URL
    let imageData: Data
    let title: String
    

    let settings: [Setting] = [
        // Core
        Setting(category: "Core", name: "use_multi_core", description: "Enable multi-core", value: true, type: .toggle),
        Setting(category: "Core", name: "use_unsafe_extended_memory_layout", description: "Enable unsafe extended memory layout", value: false, type: .toggle),
        
        // CPU
        Setting(category: "Cpu", name: "cpu_accuracy", description: "CPU accuracy", value: 0.0, type: .slider, range: 0...2),
        Setting(category: "Cpu", name: "cpu_debug_mode", description: "Enable CPU debug mode", value: false, type: .toggle),
        Setting(category: "Cpu", name: "cpuopt_page_tables", description: "Enable page tables optimization", value: true, type: .toggle),
        Setting(category: "Cpu", name: "cpuopt_block_linking", description: "Enable block linking optimization", value: true, type: .toggle),
        Setting(category: "Cpu", name: "cpuopt_return_stack_buffer", description: "Enable return stack buffer optimization", value: true, type: .toggle),
        Setting(category: "Cpu", name: "cpuopt_fast_dispatcher", description: "Enable fast dispatcher optimization", value: true, type: .toggle),
        Setting(category: "Cpu", name: "cpuopt_context_elimination", description: "Enable context elimination optimization", value: true, type: .toggle),
        Setting(category: "Cpu", name: "cpuopt_const_prop", description: "Enable constant propagation", value: true, type: .toggle),
        Setting(category: "Cpu", name: "cpuopt_misc_ir", description: "Enable miscellaneous CPU optimizations", value: true, type: .toggle),
        Setting(category: "Cpu", name: "cpuopt_reduce_misalign_checks", description: "Reduce memory misalignment checks", value: true, type: .toggle),
        Setting(category: "Cpu", name: "cpuopt_fastmem", description: "Enable fast memory access", value: true, type: .toggle),
        Setting(category: "Cpu", name: "cpuopt_fastmem_exclusives", description: "Enable exclusive memory optimization", value: true, type: .toggle),
        Setting(category: "Cpu", name: "cpuopt_recompile_exclusives", description: "Enable recompile exclusives", value: true, type: .toggle),
        Setting(category: "Cpu", name: "cpuopt_ignore_memory_aborts", description: "Ignore memory aborts", value: true, type: .toggle),
        Setting(category: "Cpu", name: "cpuopt_unsafe_unfuse_fma", description: "Enable unsafe FMA unfuse", value: true, type: .toggle),
        Setting(category: "Cpu", name: "cpuopt_unsafe_reduce_fp_error", description: "Reduce floating-point error", value: true, type: .toggle),
        Setting(category: "Cpu", name: "cpuopt_unsafe_ignore_standard_fpcr", description: "Ignore standard FPCR", value: true, type: .toggle),
        Setting(category: "Cpu", name: "cpuopt_unsafe_inaccurate_nan", description: "Inaccurate NaN handling", value: true, type: .toggle),
        Setting(category: "Cpu", name: "cpuopt_unsafe_fastmem_check", description: "Disable fast memory checks", value: true, type: .toggle),
        Setting(category: "Cpu", name: "cpuopt_unsafe_ignore_global_monitor", description: "Ignore global monitor", value: true, type: .toggle),
        
        // Renderer
        Setting(category: "Renderer", name: "backend", description: "Backend API", value: 1.0, type: .slider, range: 0...2),
        Setting(category: "Renderer", name: "async_presentation", description: "Enable async presentation", value: true, type: .toggle),
        Setting(category: "Renderer", name: "force_max_clock", description: "Force max GPU clock", value: false, type: .toggle),
        Setting(category: "Renderer", name: "debug", description: "Enable debug mode", value: false, type: .toggle),
        Setting(category: "Renderer", name: "renderer_shader_feedback", description: "Enable shader feedback", value: false, type: .toggle),
        Setting(category: "Renderer", name: "nsight_aftermath", description: "Enable Nsight Aftermath", value: false, type: .toggle),
        Setting(category: "Renderer", name: "disable_shader_loop_safety_checks", description: "Disable shader loop safety checks", value: false, type: .toggle),
        Setting(category: "Renderer", name: "resolution_setup", description: "Resolution setup", value: 2.0, type: .slider, range: 0...7),
        Setting(category: "Renderer", name: "scaling_filter", description: "Scaling filter", value: 1.0, type: .slider, range: 0...5),
        Setting(category: "Renderer", name: "anti_aliasing", description: "Anti-Aliasing", value: 0.0, type: .slider, range: 0...1),
        Setting(category: "Renderer", name: "fullscreen_mode", description: "Fullscreen mode", value: 0.0, type: .slider, range: 0...1),
        Setting(category: "Renderer", name: "aspect_ratio", description: "Aspect ratio", value: 0.0, type: .slider, range: 0...4),
        Setting(category: "Renderer", name: "max_anisotropy", description: "Anisotropic filtering", value: 0.0, type: .slider, range: 0...4),
        Setting(category: "Renderer", name: "use_vsync", description: "VSync mode", value: 1.0, type: .slider, range: 0...3),
        
        // Audio
        Setting(category: "Audio", name: "output_engine", description: "Audio output engine", value: "auto", type: .textField),
        Setting(category: "Audio", name: "output_device", description: "Audio output device", value: "auto", type: .textField),
        Setting(category: "Audio", name: "volume", description: "Output volume", value: 100.0, type: .slider, range: 0...100),
        
        // Data Storage
        Setting(category: "Data Storage", name: "use_virtual_sd", description: "Use virtual SD card", value: false, type: .toggle),
        Setting(category: "Data Storage", name: "gamecard_inserted", description: "Enable gamecard emulation", value: false, type: .toggle),
        
        // System
        Setting(category: "System", name: "use_docked_mode", description: "Enable docked mode", value: false, type: .toggle),
        Setting(category: "System", name: "rng_seed_enabled", description: "Enable RNG seed", value: false, type: .toggle),
        Setting(category: "System", name: "rng_seed", description: "RNG seed value", value: "12345", type: .textField),
        Setting(category: "System", name: "custom_rtc_enabled", description: "Enable custom RTC", value: false, type: .toggle),
        Setting(category: "System", name: "language_index", description: "System language", value: 1.0, type: .slider, range: 0...17),
        Setting(category: "System", name: "region_index", description: "System region", value: -1.0, type: .slider, range: -1...6),
        
        // Miscellaneous
        Setting(category: "Miscellaneous", name: "log_filter", description: "Log filter", value: "*:Trace", type: .textField),
        
        // Debugging
        Setting(category: "Debugging", name: "record_frame_times", description: "Record frame times", value: false, type: .toggle),
        Setting(category: "Debugging", name: "reporting_services", description: "Verbose reporting services", value: false, type: .toggle)
    ]

    /*
    let settings: [String: [String: String]] = [
        "Core": [
            "use_multi_core": "Whether to use multi-core for CPU emulation (0: Disabled, 1 (default): Enabled)",
            "use_unsafe_extended_memory_layout": "Enable unsafe extended guest system memory layout (8GB DRAM) (0 (default): Disabled, 1: Enabled)"
        ],
        "Cpu": [
            "cpu_accuracy": "Adjusts various optimizations (0 (default): Auto-select, 1: Accurate, 2: Unsafe)",
            "cpu_debug_mode": "Allow disabling safe optimizations (0 (default): Disabled, 1: Enabled)",
            "cpuopt_page_tables": "Enable inline page tables optimization (faster guest memory access) (0: Disabled, 1 (default): Enabled)",
            "cpuopt_block_linking": "Enable block linking CPU optimization (reduce block dispatcher use during predictable jumps) (0: Disabled, 1 (default): Enabled)",
            "cpuopt_return_stack_buffer": "Enable return stack buffer CPU optimization (reduce block dispatcher use during predictable returns) (0: Disabled, 1 (default): Enabled)",
            "cpuopt_fast_dispatcher": "Enable fast dispatcher CPU optimization (two-tiered dispatcher architecture) (0: Disabled, 1 (default): Enabled)",
            "cpuopt_context_elimination": "Enable context elimination CPU Optimization (reduce host memory use for guest context) (0: Disabled, 1 (default): Enabled)",
            "cpuopt_const_prop": "Enable constant propagation CPU optimization (basic IR optimization) (0: Disabled, 1 (default): Enabled)",
            "cpuopt_misc_ir": "Enable miscellaneous CPU optimizations (basic IR optimization) (0: Disabled, 1 (default): Enabled)",
            "cpuopt_reduce_misalign_checks": "Enable reduction of memory misalignment checks (0: Disabled, 1 (default): Enabled)",
            "cpuopt_fastmem": "Enable Host MMU Emulation (faster guest memory access) (0: Disabled, 1 (default): Enabled)",
            "cpuopt_fastmem_exclusives": "Enable Host MMU Emulation for exclusive memory instructions (0: Disabled, 1 (default): Enabled)",
            "cpuopt_recompile_exclusives": "Enable fallback on failure of fastmem for exclusive memory instructions (0: Disabled, 1 (default): Enabled)",
            "cpuopt_ignore_memory_aborts": "Enable optimization to ignore invalid memory accesses (0: Disabled, 1 (default): Enabled)",
            "cpuopt_unsafe_unfuse_fma": "Enable unfuse FMA (improve performance on CPUs without FMA) (0: Disabled, 1 (default): Enabled)",
            "cpuopt_unsafe_reduce_fp_error": "Enable faster FRSQRTE and FRECPE (0: Disabled, 1 (default): Enabled)",
            "cpuopt_unsafe_ignore_standard_fpcr": "Enable faster ASIMD instructions (32 bits only) (0: Disabled, 1 (default): Enabled)",
            "cpuopt_unsafe_inaccurate_nan": "Enable inaccurate NaN handling (0: Disabled, 1 (default): Enabled)",
            "cpuopt_unsafe_fastmem_check": "Disable address space checks (64 bits only) (0: Disabled, 1 (default): Enabled)",
            "cpuopt_unsafe_ignore_global_monitor": "Enable faster exclusive instructions (0: Disabled, 1 (default): Enabled)"
        ],
        "Renderer": [
            "backend": "Which backend API to use (0: OpenGL, 1 (default): Vulkan, 2: Null)",
            "async_presentation": "Enable asynchronous presentation (Vulkan only) (0: Off, 1 (default): On)",
            "force_max_clock": "Forces GPU to run at max clock (0 (default): Disabled, 1: Enabled)",
            "debug": "Enable graphics API debugging mode (0 (default): Disabled, 1: Enabled)",
            "renderer_shader_feedback": "Enable shader feedback (0 (default): Disabled, 1: Enabled)",
            "nsight_aftermath": "Enable Nsight Aftermath crash dumps (0 (default): Disabled, 1: Enabled)",
            "disable_shader_loop_safety_checks": "Disable shader loop safety checks (0 (default): Disabled, 1: Enabled)",
            "vulkan_device": "Which Vulkan physical device to use (default is 0)",
            "resolution_setup": "Resolution setup (default: 2 (720p/1080p))",
            "scaling_filter": "Pixel filter for frame up/down-sampling (0: Nearest, 1 (default): Bilinear, 2: Bicubic, etc.)",
            "anti_aliasing": "Anti-Aliasing (0 (default): None, 1: FXAA)",
            "fullscreen_mode": "Fullscreen or borderless window mode (0: Borderless, 1: Fullscreen)",
            "aspect_ratio": "Aspect ratio (0: 16:9, 1: 4:3, 2: 21:9, etc.)",
            "max_anisotropy": "Anisotropic filtering level (default: 0)",
            "use_vsync": "Enable VSync (0: Immediate, 1 (default): Mailbox, etc.)",
            "shader_backend": "Select OpenGL shader backend (0: GLSL, 1 (default): GLASM, 2: SPIR-V)",
            "use_asynchronous_shaders": "Allow asynchronous shader building (0 (default): Off, 1: On)",
            "use_reactive_flushing": "Reactive memory flushing (0 (default): Off, 1: On)",
            "nvdec_emulation": "NVDEC emulation (0: Disabled, 1: CPU Decoding, 2 (default): GPU Decoding)",
            "accelerate_astc": "Accelerate ASTC texture decoding (0 (default): Off, 1: On)",
            "use_speed_limit": "Limit emulation speed (0: Off, 1 (default): On)",
            "speed_limit": "Limit game speed to a percentage of target (default: 100%)",
            "use_disk_shader_cache": "Use disk-based shader cache (0: Off, 1 (default): On)",
            "gpu_accuracy": "GPU accuracy level (0 (default): Normal, 1: High, 2: Extreme)",
            "use_asynchronous_gpu_emulation": "Enable asynchronous GPU emulation (0: Off, 1 (default): On)",
            "use_fast_gpu_time": "Enable fast GPU time reporting (0: Off, 1 (default): On)",
            "use_pessimistic_flushes": "Force flush unmodified buffers (0 (default): Off, 1: On)",
            "use_caches_gc": "Use garbage collection for GPU caches (0 (default): Off, 1: On)",
            "bg_red": "Clear color for red (0-255, default: 0)",
            "bg_blue": "Clear color for blue (0-255, default: 0)",
            "bg_green": "Clear color for green (0-255, default: 0)"
        ],
        "Audio": [
            "output_engine": "Audio output engine (default: auto)",
            "output_device": "Audio device (default: auto)",
            "volume": "Output volume (default: 100%)"
        ],
        "Data Storage": [
            "use_virtual_sd": "Enable virtual SD card (1: Yes, 0 (default): No)",
            "gamecard_inserted": "Enable gamecard emulation (1: Yes, 0 (default): No)",
            "gamecard_current_game": "Emulate gamecard as current game (1: Yes, 0 (default): No)",
            "gamecard_path": "Path to XCI file for gamecard emulation"
        ],
        "System": [
            "use_docked_mode": "Use docked mode (1: Yes, 0 (default): No)",
            "rng_seed_enabled": "Enable RNG seed",
            "rng_seed": "Seed for RNG generator",
            "custom_rtc_enabled": "Enable custom RTC time override",
            "custom_rtc": "Override time in seconds since 1970",
            "language_index": "System language index (0: Japanese, 1: English, etc.)",
            "region_index": "System region (default: -1, 0: Japan, 1: USA, etc.)",
            "time_zone_index": "Time zone index (default: 0)",
            "sound_index": "Sound output mode (0: Mono, 1 (default): Stereo, 2: Surround)"
        ],
        "Miscellaneous": [
            "log_filter": "Filter log messages (e.g., *:Trace)"
        ],
        "Debugging": [
            "record_frame_times": "Record frame time data",
            "dump_exefs": "Dump ExeFS while loading games",
            "dump_nso": "Dump all NSOs while loading",
            "enable_fs_access_log": "Save filesystem access log",
            "reporting_services": "Enable verbose reporting services",
            "quest_flag": "Set emulation console to Kiosk Mode (false: Retail/Normal, true: Kiosk)",
            "use_debug_asserts": "Enable debug asserts",
            "use_auto_stub": "Automatically stub unimplemented HLE service calls",
            "disable_macro_jit": "Disable macro JIT compiler",
            "use_gdbstub": "Enable GDB remote debugging",
            "gdbstub_port": "GDB debugging port (default: 1234)",
            "wait_for_gdb": "Wait for debugger on launch"
        ]
    ]
     */

    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(developer)
        hasher.combine(fileURL)
        hasher.combine(imageData)
        hasher.combine(title)
    }
    
    static func < (lhs: PomeloGame, rhs: PomeloGame) -> Bool {
        lhs.title < rhs.title
    }
    
    static func == (lhs: PomeloGame, rhs: PomeloGame) -> Bool {
        lhs.title == rhs.title
    }
}


struct Setting {
    var category: String
    var name: String
    var description: String
    var value: Any
    var type: SettingType
    var range: ClosedRange<Double>? // Only for slider values
}

enum SettingType {
    case toggle
    case slider
    case textField
}
