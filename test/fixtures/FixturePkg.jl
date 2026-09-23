# Fixtures for the checker tests: real functions with real docstrings, so
# method introspection runs for real. The first three docstrings are copied
# verbatim from the design's `conv2d_example.jl`.
module FixturePkg

    using DocumenterDocstringStyle: MINIMAL, NOSCHEMA
    using DocStringExtensions: TYPEDSIGNATURES

    """
        conv2d(x, w; bias=nothing, stride=1, pad=0, dilation=1, groups=1) -> AbstractArray{T,4}

    Apply a 2D convolution over an input image composed of several input planes.

    See [`Conv2d`](@ref) for the layer version and the output size formula.

    # Arguments
    - `x::AbstractArray{T,4}`: input of size `(iW, iH, in_channels, batch)`.
    - `w::AbstractArray{T,4}`: filters of size `(kW, kH, in_channels ÷ groups, out_channels)`.

    # Keywords
    - `bias::Union{Nothing,AbstractVector} = nothing`: optional bias of length `out_channels`.
    - `stride::Union{Int,NTuple{2,Int}} = 1`: kernel stride, `s` or `(sW, sH)`.
    - `pad::Union{Int,NTuple{2,Int},Symbol} = 0`: implicit padding on both sides.
      `:valid` means no padding. `:same` pads so the output keeps the input's
      spatial size and requires `stride == 1`.
    - `dilation::Union{Int,NTuple{2,Int}} = 1`: spacing between kernel elements.
    - `groups::Int = 1`: number of channel groups. `in_channels` and
      `out_channels` must both be divisible by it.

    # Returns
    - `AbstractArray{T,4}` of size `(oW, oH, out_channels, batch)`.

    # Throws
    - `ArgumentError`: if `pad = :same` and `stride != 1`.
    - `DimensionMismatch`: if channel counts are not divisible by `groups`.

    # Notes
    !!! warning "Performance"
        With `pad = :same`, an even-sized kernel combined with an odd `dilation`
        in any dimension requires an explicit internal `pad` call.

    !!! note "Determinism"
        On CUDA with cuDNN a nondeterministic algorithm may be selected for speed.
        See the Reproducibility page for how to force deterministic kernels.

    Supports `ComplexF32` and `ComplexF64` element types.

    # Examples
    ```jldoctest
    julia> x = randn(Float32, 5, 5, 4, 1);

    julia> w = randn(Float32, 3, 3, 4, 8);

    julia> size(conv2d(x, w; pad=1))
    (5, 5, 8, 1)
    ```

    # See also
    [`conv_transpose2d`](@ref), [`Conv2d`](@ref)
    """
    function conv2d(
            x::AbstractArray{T, 4}, w::AbstractArray{T, 4};
            bias = nothing, stride = 1, pad = 0, dilation = 1, groups = 1
        ) where {T}
        # ...
    end

    # Simple function: whole-docstring opt-out, only signature + summary checked.
    """
        channels(x) -> Int

    Return the number of channels of a WHCN array.

    $(MINIMAL)
    """
    channels(x::AbstractArray{<:Any, 4}) = size(x, 3)

    # Per-section opt-out: section present but explicitly empty.
    """
        reset_cache!() -> Nothing

    Clear the internal kernel-selection cache.

    # Returns
    N/A

    # Examples
    N/A
    """
    reset_cache!() = nothing

    # Whole-docstring skip: nothing is checked.
    """
    $(NOSCHEMA)
    """
    skipped(x) = x

    """
        splat(xs...; kw...) -> Int

    Count the positional arguments.

    # Arguments
    - `xs...`: values to count.

    # Keywords
    - `kw...`: ignored.

    # Returns
    The number of values.

    # Examples
    ```jldoctest
    julia> splat(1, 2)
    2
    ```
    """
    splat(xs...; kw...) = length(xs)

    """
        twomethods(a::Int) -> Int

    Double an integer.

    # Arguments
    - `a::Int`: the integer.

    # Returns
    Twice `a`.

    # Examples
    ```jldoctest
    julia> twomethods(2)
    4
    ```
    """
    twomethods(a::Int) = 2a

    """
        twomethods(b::String) -> String

    Repeat a string twice.

    # Arguments
    - `b::String`: the string.

    # Returns
    `b` repeated twice.

    # Examples
    ```jldoctest
    julia> twomethods("a")
    "aa"
    ```
    """
    twomethods(b::String) = b^2

    # Undocumented generic fallback with a different argument name.
    fallback(value) = value

    """
        fallback(x::Int) -> Int

    Return `x` unchanged.

    # Arguments
    - `x::Int`: the value.

    # Returns
    `x`.

    # Examples
    ```jldoctest
    julia> fallback(1)
    1
    ```
    """
    fallback(x::Int) = x

    """
    $(TYPEDSIGNATURES)

    Return `x` plus one.

    # Arguments
    - `x::Int`: the value.

    # Returns
    `x + 1`.

    # Examples
    ```jldoctest
    julia> typed(1)
    2
    ```
    """
    typed(x::Int) = x + 1

    """
        multi_paragraph(x) -> Int

    Return one.

    # Arguments
    - `x`: ignored.

      A second paragraph, which a table cell cannot hold.

    # Returns
    One.

    # Examples
    ```jldoctest
    julia> multi_paragraph(2)
    1
    ```
    """
    multi_paragraph(x) = 1

end

# Fixtures that break the schema. The first is the broken `conv2d` from the
# design's preview.
module FixtureBad

    using DocumenterDocstringStyle: MINIMAL, NOSCHEMA


    """
        conv2d(x, w; stride=1, pad=0, groups=1)

    # Arguments
    - `x`: input array.
    - `weight`: filters.

    # Keywords
    - `stride = 1`: kernel stride.
    - `pad = 0`: padding.

    # Example
    ```julia
    julia> conv2d(x, w)
    ```
    """
    function conv2d(x, w; stride = 1, pad = 0, groups = 1)
        # ...
    end


    """
        wrong_order(x) -> Int

    Return one.

    # Arguments
    - `x`: ignored.

    # Examples
    ```jldoctest
    julia> wrong_order(2)
    1
    ```

    # Returns
    One.
    """
    wrong_order(x) = 1

    """
        duplicate_notes(x) -> Int

    Return one.

    # Arguments
    - `x`: ignored.

    # Returns
    One.

    # Notes
    First.

    # Notes
    Second.

    # Examples
    ```jldoctest
    julia> duplicate_notes(2)
    1
    ```
    """
    duplicate_notes(x) = 1

    """
        plain_example(x) -> Int

    Return one.

    # Arguments
    - `x`: ignored.

    # Returns
    One.

    # Examples
    ```julia
    julia> plain_example(2)
    1
    ```
    """
    plain_example(x) = 1

    """
        bad_keyword_item(; stride = 1, pad = 0) -> Int

    Return the stride.

    # Keywords
    - `stride = 1`: kernel stride.
    - pad: padding, without a leading code span.

    # Returns
    The stride.

    # Examples
    ```jldoctest
    julia> bad_keyword_item()
    1
    ```
    """
    bad_keyword_item(; stride = 1, pad = 0) = stride

    """
        both_markers(x)

    Use both markers.

    $(MINIMAL)
    $(NOSCHEMA)
    """
    both_markers(x) = x

    """
    No signature block and no summary sentence end
    """
    nosignature() = nothing

end
