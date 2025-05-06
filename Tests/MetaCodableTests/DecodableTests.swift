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

struct DecodableTests {
    struct WithoutAvailableAttribute {
        @Decodable
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
                @Decodable
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

                    @available(*, deprecated, message: "Deprecated") extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decode(String.self, forKey: CodingKeys.value)
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
        @Decodable
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
                @Decodable
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

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decode(String.self, forKey: CodingKeys.value)
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
        @Decodable
        struct SomeCodable {
            let value1: String?
            let value2: String!
            let value3: Optional<String>
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Decodable
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

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value1 = try container.decodeIfPresent(String.self, forKey: CodingKeys.value1)
                            self.value2 = try container.decodeIfPresent(String.self, forKey: CodingKeys.value2)
                            self.value3 = try container.decodeIfPresent(String.self, forKey: CodingKeys.value3)
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
        @Decodable
        struct SomeCodable: Swift.Encodable {
            let value: String

            func encode(to encoder: any Encoder) throws {
            }
        }

        @Test
        func expansion() throws {
            assertMacroExpansion(
                """
                @Decodable
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

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decode(String.self, forKey: CodingKeys.value)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case value = "value"
                        }
                    }
                    """,
                conformsTo: ["Decodable"]
            )
        }
    }

    struct IgnoredCodableConformance {
        @Decodable
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
                @Decodable
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
        class SuperCodable: Decodable {}
        enum AnotherDecoder {}
        enum AnotherEncoder {}

        @Decodable
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
                @Decodable
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

                        required init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.value = try container.decode(String.self, forKey: CodingKeys.value)
                            try super.init(from: decoder)
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
        @Decodable
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
                @Decodable
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
        @Decodable
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
                @Decodable
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

