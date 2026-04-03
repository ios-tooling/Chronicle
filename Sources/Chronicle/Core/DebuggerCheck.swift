import Foundation

enum ChronicleDebugger {
	static var isAttached: Bool {
		var info = kinfo_proc()
		var size = MemoryLayout<kinfo_proc>.stride
		var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
		sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
		return (info.kp_proc.p_flag & P_TRACED) != 0
	}
}
