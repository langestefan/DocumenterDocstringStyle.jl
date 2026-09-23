# Demo module for the style pages. The `conv2d`, `channels` and `reset_cache!`
# docstrings are the design's reference docstrings, copied verbatim.
module ConvDemo

using DocumenterDocstringStyle: MINIMAL

export Conv2d, channels, conv2d, conv_transpose2d, reset_cache!

"""
    Conv2d(; w, bias = nothing, stride = 1, pad = 0, dilation = 1, groups = 1)

2D convolution layer holding filters `w` and an optional `bias`.

Calling the layer on `x` applies [`conv2d`](@ref) with the stored settings. The
output has size `((iW + 2pad - dilation * (kW - 1) - 1) ÷ stride + 1, ...)` in each
spatial dimension.
"""
Base.@kwdef struct Conv2d{W, B}
    w::W
    bias::B = nothing
    stride::Int = 1
    pad::Int = 0
    dilation::Int = 1
    groups::Int = 1
end

(c::Conv2d)(x) = conv2d(x, c.w; c.bias, c.stride, c.pad, c.dilation, c.groups)

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
    iW, iH, cin, n = size(x)
    kW, kH, cing, cout = size(w)
    if cin % groups != 0 || cout % groups != 0 || cin ÷ groups != cing
        throw(DimensionMismatch("channel counts must be divisible by groups = $groups"))
    end
    sW, sH = pair(stride)
    dW, dH = pair(dilation)
    if pad === :same
        stride == 1 || throw(ArgumentError("pad = :same requires stride == 1"))
        pW, pH = dW * (kW - 1) ÷ 2, dH * (kH - 1) ÷ 2
    elseif pad === :valid
        pW, pH = 0, 0
    else
        pW, pH = pair(pad)
    end
    oW = (iW + 2pW - dW * (kW - 1) - 1) ÷ sW + 1
    oH = (iH + 2pH - dH * (kH - 1) - 1) ÷ sH + 1
    y = zeros(T, oW, oH, cout, n)
    coutg = cout ÷ groups
    for b in 1:n, o in 1:cout, j in 1:oH, i in 1:oW
        g = (o - 1) ÷ coutg
        acc = bias === nothing ? zero(T) : T(bias[o])
        for c in 1:cing, q in 1:kH, p in 1:kW
            xi = (i - 1) * sW - pW + (p - 1) * dW + 1
            xj = (j - 1) * sH - pH + (q - 1) * dH + 1
            if 1 <= xi <= iW && 1 <= xj <= iH
                acc += x[xi, xj, g * cing + c, b] * w[p, q, c, o]
            end
        end
        y[i, j, o, b] = acc
    end
    return y
end

pair(v::Integer) = (Int(v), Int(v))
pair(v::NTuple{2, Integer}) = (Int(v[1]), Int(v[2]))

"""
    conv_transpose2d(x, w; stride = 1, pad = 0) -> AbstractArray{T,4}

Apply a 2D transposed convolution, the adjoint of [`conv2d`](@ref).

$(MINIMAL)
"""
conv_transpose2d(x, w; stride = 1, pad = 0) = error("not implemented in this demo")

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

end
