euler(u, W, P) = euler!(copy(W), u, W, P)
function euler!{T}(Y, u, W::SamplePath{T}, P)

    N = length(W)
    N != length(Y) && error("Y and W differ in length.")

    ww = W.yy
    tt = Y.tt
    yy = Y.yy
    tt[:] = W.tt

    y = u

    for i in 1:N-1
        yy[.., i] = y
        y = y + b(tt[i], y, P)*(tt[i+1]-tt[i]) + σ(tt[i], y, P)*(ww[.., i+1]-ww[..,i])
    end
    yy[.., N] = y
    Y
end
mdb(u, W, P) = mdb!(copy(W), u, W, P)
function mdb!{T}(Y, u, W::SamplePath{T}, P)

    N = length(W)
    N != length(Y) && error("Y and W differ in length.")

    ww = W.yy
    tt = Y.tt
    yy = Y.yy
    tt[:] = W.tt

    y = u

    for i in 1:N-1
        yy[.., i] = y
        y = y + b(tt[i], y, P)*(tt[i+1]-tt[i]) + σ(tt[i], y, P)*sqrt((tt[end]-tt[i+1])/(tt[end]-tt[i]))*(ww[.., i+1]-ww[..,i])
    end
    yy[.., N] = y
    Y
end

bridge(W, P, scheme! = euler!) = bridge!(copy(W), W, P, scheme!)
function bridge!{T}(Y, W::SamplePath{T}, P, scheme! = euler!)
    W.tt[1] != P.t0 && error("time axis mismatch between W and P  ")
    W.tt[end] != P.t1 && error("time axis mismatch between W and P  ")

    scheme!(Y, P.v0, W, P)
    Y.yy[.., length(W.tt)] = P.v1
    Y
end

rungekutta(W, P) = rungekutta!(copy(W), W, P)
function rungekutta!{T<:Number}(Y, u, W::SamplePath{T}, P)

    N = length(W)
    N != length(Y) && error("Y and W differ in length.")
 
    ww = W.yy
    tt = Y.tt
    yy = Y.yy
    tt[:] = W.tt

    y = u

    for i in 1:N-1
        yy[.., i] = y
        delta = tt[i+1]-tt[i]
        sqdelta = sqrt(delta)
        B = b(tt[i], y, P)
        S = σ(tt[i], y, P)
        dw = ww[.., i+1]-ww[..,i]
        y = y + B*delta + S*dw
        ups = y + B*delta + S*sqdelta
        y = y + 0.5(σ(tt[i+1], ups, P) - S)*(dw^2 - delta)/sqdelta
        
    end
    yy[.., N] = y
    SamplePath{T}(tt, yy)
end


# euler for bridges starting from P.v0 to P.v1 


eulerMu(W, P) = eulerMu!(copy(W), W, P)
function eulerMu!{T}(Y, W::SamplePath{T}, P)

    N = length(W)
    N != length(Y) && error("Y and W differ in length.")

    ww = W.yy
    tt = Y.tt
    
    tt[1] != P.t0 && error("time axis mismatch between W and P  ")
    tt[end] != P.t1 && error("time axis mismatch between W and P  ")
    
    yy = Y.yy
    tt[:] = W.tt

    y = P.v0

    for i in 1:N-1
        yy[.., i] = y
        ynew = Mu(tt[i+1], P.t1, P.Pt)*inv(Mu(tt[i], P.t1, P.Pt))*y
        y = ynew + (b(tt[i], y, P) - P.Pt.B*y  + (a(tt[i], y, P)-P.Pt.a)*r(tt[i], y, P))*(tt[i+1]-tt[i]) + σ(tt[i], y, P)*(ww[.., i+1]-ww[..,i])
    end
    yy[.., N] = P.v1
    SamplePath{T}(tt, yy)
end


shiftedbridge(W, P) = shiftedbridge!(copy(W), W, P)
function shiftedbridge!{T}(Y, W::SamplePath{T}, P)

    N = length(W)
    N != length(Y) && error("Y and W differ in length.")

    ww = W.yy
    tt = Y.tt
    
    tt[1] != P.t0 && error("time axis mismatch between W and P  ")
    tt[end] != P.t1 && error("time axis mismatch between W and P  ")
    
    yy = Y.yy
    tt[:] = W.tt

    y = P.v0 

    for i in 1:N-1
        yy[.., i] = y 
        y = y - V(tt[i], P) + V(tt[i+1], P)  + (b(tt[i], y, P) - dotV(tt[i], P))  *(tt[i+1]-tt[i]) + σ(tt[i], y, P)*(ww[.., i+1]-ww[..,i])
    end
    yy[.., N] = P.v1
    SamplePath{T}(tt, yy)
end

innovations(Y, P) = innovations!(copy(Y), Y, P)
function innovations!{T}(W, Y::SamplePath{T}, P)

    N = length(W)
    N != length(Y) && error("Y and W differ in length.")

    yy = Y.yy
    tt = Y.tt
    ww = W.yy
    W.tt[:] = Y.tt

    w = zero(ww[.., 1])

    for i in 1:N-1
        ww[.., i] = w
        w = w + inv(σ(tt[i], yy[.., i], P))*(yy[.., i+1] - yy[.., i] - b(tt[i], yy[.., i], P)*(tt[i+1]-tt[i])) 
    end
    ww[.., N] = w
    SamplePath{T}(tt, ww)
end

mdbinnovations(Y, P) = mdbinnovations!(copy(Y), Y, P)
function mdbinnovations!{T}(W, Y::SamplePath{T}, P)

    N = length(W)
    N != length(Y) && error("Y and W differ in length.")

    yy = Y.yy
    tt = Y.tt
    ww = W.yy
    W.tt[:] = Y.tt

    w = zero(ww[.., 1])

    for i in 1:N-1
        ww[.., i] = w
        w = w + sqrt((tt[end]-tt[i+1])/(tt[end]-tt[i]))\inv(σ(tt[i], yy[.., i], P))*(yy[.., i+1] - yy[.., i] - b(tt[i], yy[.., i], P)*(tt[i+1]-tt[i])) 
    end
    ww[.., N] = w
    SamplePath{T}(tt, ww)
end
