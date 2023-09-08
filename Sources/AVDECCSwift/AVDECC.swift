import CAVDECC

extension UnsafePointer {
    func propertyBasePointer<Property>(to property: KeyPath<Pointee, Property>)
        -> UnsafePointer<Property>?
    {
        guard let offset = MemoryLayout<Pointee>.offset(of: property) else { return nil }
        return (UnsafeRawPointer(self) + offset).assumingMemoryBound(to: Property.self)
    }
}

public final class AVDECC {
    public var shared = AVDECC()

    public static var interfaceVersion: avdecc_interface_version_t {
        LA_AVDECC_getInterfaceVersion()
    }

    public static var version: String {
        String(cString: LA_AVDECC_getVersion())
    }

    init() {
        LA_AVDECC_initialize()
    }

    deinit {
        LA_AVDECC_uninitialize()
    }
}

public extension avdecc_unique_identifier_t {
    static var null: Self {
        LA_AVDECC_getNullUniqueIdentifier()
    }
}

public extension String {
    init(avdeccFixedString: avdecc_fixed_string_t) {
        self.init(withUnsafePointer(to: avdeccFixedString) { pointer in
            let start = pointer.propertyBasePointer(to: \.0)!
            return start.withMemoryRebound(
                to: UInt8.self,
                capacity: MemoryLayout.size(ofValue: pointer)
            ) {
                String(cString: $0)
            }
        })
    }
}

