@testitem "Aqua quality assurance" tags = [:quality] begin
    using Aqua: Aqua
    Aqua.test_all(DocumenterDocstringStyle)
end

@testitem "JET static analysis" tags = [:quality] begin
    using JET: JET
    JET.test_package(DocumenterDocstringStyle; target_modules = (DocumenterDocstringStyle,))
end
