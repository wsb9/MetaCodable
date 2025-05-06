import MetaCodable
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import Testing

@testable import PluginCore

#if canImport(SwiftSyntax600)
import SwiftSyntaxMacrosGenericTestSupport
#else
import SwiftSyntaxMacrosTestSupport
#endif

struct EncodableTests {
    struct WithoutAvailableAttribute {
        @Encodable
        @available(*, deprecated, message: "Deprecated")
        struct SomeCodable {
            let value: String
            static let other: String = "other"
            public private(set) static var otherM: String {
                get { "otherM" }
                set { Issue.record("Invalid setter invocation") }
            }
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Encodable
                @available(*, deprecated, message: "Deprecated")
                struct SomeCodable {
                    let value: String
                    static let other: String = "other"
                    public private(set) static var otherM: String {
                        get { "otherM" }
                        set { Issue.record("Invalid setter invocation") }
                    }
                }
                """,
                expandedSource:
                    """
                    @available(*, deprecated, message: "Deprecated")
                    struct SomeCodable {
                        let value: String
                        static let other: String = "other"
                        public private(set) static var otherM: String {
                            get { "otherM" }
                            set { Issue.record("Invalid setter invocation") }
                        }
                    }

                    @available(*, deprecated, message: "Deprecated") extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.value, forKey: CodingKeys.value)
                        }
                    }

                    @available(*, deprecated, message: "Deprecated") extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                        }
                    }
                    """
            )
        }
    }

    struct WithoutAnyCustomization {
        @Encodable
        struct SomeCodable {
            let value: String
            static let other: String = "other"
            public private(set) static var otherM: String {
                get { "otherM" }
                set { Issue.record("Invalid setter invocation") }
            }
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Encodable
                struct SomeCodable {
                    let value: String
                    static let other: String = "other"
                    public private(set) static var otherM: String {
                        get { "otherM" }
                        set { Issue.record("Invalid setter invocation") }
                    }
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value: String
                        static let other: String = "other"
                        public private(set) static var otherM: String {
                            get { "otherM" }
                            set { Issue.record("Invalid setter invocation") }
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.value, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                        }
                    }
                    """
            )
        }
    }

    struct WithOptionalTypeWithoutAnyCustomization {
        @Encodable
        struct SomeCodable {
            let value1: String?
            let value2: String!
            let value3: Optional<String>
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Encodable
                struct SomeCodable {
                    let value1: String?
                    let value2: String!
                    let value3: Optional<String>
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let value1: String?
                        let value2: String!
                        let value3: Optional<String>
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encodeIfPresent(self.value1, forKey: CodingKeys.value1)
                            try container.encodeIfPresent(self.value2, forKey: CodingKeys.value2)
                            try container.encodeIfPresent(self.value3, forKey: CodingKeys.value3)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value1 = "value1"
                            case value2 = "value2"
                            case value3 = "value3"
                        }
                    }
                    """
            )
        }
    }

    struct OnlyDecodeConformance {
        @Encodable
        struct SomeCodable: Encodable {
            let value: String

            func encode(to encoder: any Encoder) throws {
            }
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Encodable
                struct SomeCodable: Encodable {
                    let value: String

                    func encode(to encoder: any Encoder) throws {
                    }
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable: Encodable {
                        let value: String

                        func encode(to encoder: any Encoder) throws {
                        }
                    }
                    """,
                conformsTo: ["Decodable"]
            )
        }
    }

    struct OnlyEncodeConformance {
        @Encodable
        struct SomeCodable: Swift.Decodable {
            let value: String

            init(from decoder: any Decoder) throws {
                self.value = "some"
            }
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Encodable
                struct SomeCodable: Decodable {
                    let value: String

                    init(from decoder: any Decoder) throws {
                        self.value = "some"
                    }
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable: Decodable {
                        let value: String

                        init(from decoder: any Decoder) throws {
                            self.value = "some"
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.value, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                        }
                    }
                    """,
                conformsTo: ["Encodable"]
            )
        }
    }

    struct IgnoredCodableConformance {
        @Encodable
        struct SomeCodable: Swift.Codable {
            let value: String

            init(from decoder: any Decoder) throws {
                self.value = "some"
            }

            func encode(to encoder: any Encoder) throws {
            }
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Encodable
                struct SomeCodable: Codable {
                    let value: String

                    init(from decoder: any Decoder) throws {
                        self.value = "some"
                    }

                    func encode(to encoder: any Encoder) throws {
                    }
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable: Codable {
                        let value: String

                        init(from decoder: any Decoder) throws {
                            self.value = "some"
                        }

                        func encode(to encoder: any Encoder) throws {
                        }
                    }
                    """,
                conformsTo: []
            )
        }
    }

    struct SuperClassCodableConformance {
        class SuperCodable: Encodable {}
        enum AnotherDecoder {}
        enum AnotherEncoder {}

        @Encodable
        class SomeCodable: SuperCodable {
            let value: String

            required init(from decoder: AnotherDecoder) throws {
                self.value = "some"
                fatalError("No super call")
            }

            func encode(to encoder: AnotherEncoder) throws {
            }
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Encodable
                class SomeCodable: SuperCodable {
                    let value: String

                    required init(from decoder: AnotherDecoder) throws {
                        self.value = "some"
                    }

                    func encode(to encoder: AnotherEncoder) throws {
                    }
                }
                """,
                expandedSource:
                    """
                    class SomeCodable: SuperCodable {
                        let value: String

                        required init(from decoder: AnotherDecoder) throws {
                            self.value = "some"
                        }

                        func encode(to encoder: AnotherEncoder) throws {
                        }

                        override func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.value, forKey: CodingKeys.value)
                            try super.encode(to: encoder)
                        }

                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                        }
                    }
                    """,
                conformsTo: []
            )
        }
    }

    struct ClassIgnoredCodableConformance {
        @Encodable
        class SomeCodable: Swift.Codable {
            let value: String

            required init(from decoder: any Decoder) throws {
                self.value = "some"
            }

            func encode(to encoder: any Encoder) throws {
            }
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Encodable
                class SomeCodable: Codable {
                    let value: String

                    required init(from decoder: any Decoder) throws {
                        self.value = "some"
                    }

                    func encode(to encoder: any Encoder) throws {
                    }
                }
                """,
                expandedSource:
                    """
                    class SomeCodable: Codable {
                        let value: String

                        required init(from decoder: any Decoder) throws {
                            self.value = "some"
                        }

                        func encode(to encoder: any Encoder) throws {
                        }
                    }
                    """,
                conformsTo: []
            )
        }
    }

    struct ClassIgnoredCodableConformanceWithoutAny {
        @Encodable
        class SomeCodable: Swift.Codable {
            let value: String

            required init(from decoder: Decoder) throws {
                self.value = "some"
            }

            func encode(to encoder: Encoder) throws {
            }
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Encodable
                class SomeCodable: Swift.Codable {
                    let value: String

                    required init(from decoder: Decoder) throws {
                        self.value = "some"
                    }

                    func encode(to encoder: Encoder) throws {
                    }
                }
                """,
                expandedSource:
                    """
                    class SomeCodable: Swift.Codable {
                        let value: String

                        required init(from decoder: Decoder) throws {
                            self.value = "some"
                        }

                        func encode(to encoder: Encoder) throws {
                        }
                    }
                    """,
                conformsTo: []
            )
        }
    }
}

#if canImport(MacroPlugin)
@testable import MacroPlugin
#endif
