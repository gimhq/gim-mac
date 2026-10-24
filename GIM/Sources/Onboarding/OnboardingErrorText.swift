import GIMFeatures

/// The onboarding error messages for GIMFeatures' typed error kinds, from the `Onboarding` String Catalog. An
/// `.error(ErrorPresenter.Kind)` keeps the GIMFeatures text, which is English only.
enum OnboardingErrorText {
    static func serverUrl(_ kind: OnboardingValidation.ServerUrlError) -> String {
        switch kind {
        case .empty: text("onboarding.server.errorEmpty")
        case .notAFullAddress: text("onboarding.server.errorNotFull")
        }
    }

    static func displayName(_ kind: OnboardingValidation.DisplayNameError) -> String {
        switch kind {
        case .empty: text("onboarding.create.errorNameEmpty")
        case .tooLong: text("onboarding.create.errorNameTooLong")
        }
    }

    static func handle(_ kind: OnboardingValidation.HandleError) -> String {
        switch kind {
        case .empty: text("onboarding.username.errorEmpty")
        case .length: text("onboarding.username.errorLength")
        case .characters: text("onboarding.username.errorCharacters")
        }
    }

    static func claimHandle(_ kind: ClaimHandleViewModel.ErrorKind) -> String {
        switch kind {
        case .taken: text("onboarding.username.errorTaken")
        case .error(let kind): ErrorPresenter.text(for: kind)
        }
    }

    static func restore(_ kind: RestoreViewModel.ErrorKind) -> String {
        switch kind {
        case .notFound: text("onboarding.restore.errorNotFound")
        case .wrongCode: text("onboarding.restore.errorWrongCode")
        case .userIdMissing: text("onboarding.restore.errorUserIdMissing")
        case .recoveryCodeMissing: text("onboarding.restore.errorCodeMissing")
        case .kitNotRecognized: text("onboarding.restore.errorNotRecognized")
        case .kitPartMissing: text("onboarding.restore.errorIncomplete")
        case .error(let kind): ErrorPresenter.text(for: kind)
        }
    }

    static func ending(_ kind: RecoveryKitViewModel.EndingErrorKind) -> String {
        switch kind {
        case .mismatch: text("onboarding.kit.checkError")
        }
    }

    private static func text(_ key: String.LocalizationValue) -> String {
        String(localized: key, table: "Onboarding")
    }
}
