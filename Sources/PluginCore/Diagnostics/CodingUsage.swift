//
//  CodingUsage.swift
//  MetaCodable
//
//  Created by Cemen Istomin on 06.05.2025.
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros


struct CodingUsage<Attr>: DiagnosticProducer
where Attr: Attribute {
    /// The attribute to validate.
    ///
    /// Diagnostics is generated at
    /// this attribute.
    let attr: Attr
    /// The severity of produced diagnostic.
    ///
    /// Creates diagnostic with this set severity.
    let severity: DiagnosticSeverity

    /// Creates a macro-attribute combination validation instance
    /// with provided attribute, combination attribute type and severity.
    ///
    /// The provided attribute is checked to be used with the provided
    /// combination attribute type. Diagnostic with specified severity
    /// is created if that's not the case.
    ///
    /// - Parameters:
    ///   - attr: The attribute to validate.
    ///   - type: The combination attribute type.
    ///   - severity: The severity of produced diagnostic.
    ///
    /// - Returns: Newly created diagnostic producer.
    init(
        _ attr: Attr,
//        cantBeCombinedWith type: Comb.Type,
        severity: DiagnosticSeverity = .error
    ) {
        self.attr = attr
//        self.type = type
        self.severity = severity
    }

    /// Validates and produces diagnostics for the passed syntax
    /// in the macro expansion context provided.
    ///
    /// Checks whether provided macro-attribute is being used in combination
    /// with the provided combination attribute type. Diagnostic is produced
    /// with provided severity if that's not the case.
    ///
    /// - Parameters:
    ///   - syntax: The syntax to validate and produce diagnostics for.
    ///   - context: The macro expansion context diagnostics produced in.
    ///
    /// - Returns: `True` if syntax fails validation and severity is set
    ///   to error, `false` otherwise.
    @discardableResult
    func produce(
        for syntax: some SyntaxProtocol,
        in context: some MacroExpansionContext
    ) -> Bool {
        guard Codable.attributes(attachedTo: syntax).first == nil
           && DecodableMacro.attributes(attachedTo: syntax).first == nil
           && EncodableMacro.attributes(attachedTo: syntax).first == nil
        else { return false }

        let verb =
            switch severity {
            case .error:
                "must"
            default:
                "should"
            }
        let message = attr.diagnostic(
            message:
                "@\(attr.name) \(verb) be used in combination with either @Codable, @Decodable or @Encodable",
            id: attr.misuseMessageID,
            severity: severity
        )
        attr.diagnose(message: message, in: context)
        return severity == .error
    }
}

extension Attribute {
    /// Indicates this macro must be used together with
    /// the provided attribute.
    ///
    /// The created diagnostic producer produces error diagnostic,
    /// if attribute isn't used together with the provided attribute.
    ///
    /// - Parameter type: The combination attribute type.
    /// - Returns: Attribute combination usage validation
    ///   diagnostic producer.
    func mustBeCodable() -> CodingUsage<Self> {
        return .init(self)
    }
}
