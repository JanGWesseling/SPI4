using Images
using FileIO
using ImageMagick
using Plots

f="/media/wesseling/DataDisk/Wesseling/Work/SPI4/Test/test.png"
p=load(File(format"PNG",f))
q=p[15:720,50:675]
display(q)
save(f,q)

#=
gr()
x=["x1","x2","x3","x4"]
y=["y1","y2","y3","y4"]
z=rand(["A","B","C"],4,4)

p=heatmap(x,y,z, c=cgrad([:red,:green,:blue]),size=(100,100))

q = convert(Array{RGB}(undef,100,100),p)



z=Array{Int64}(undef,4,4)
for i in 1:4
    for j in 1:4
        z[i,j] = rand(1:10)
    end
end
println(z)
txt = ["One","Two","Three","Four","Five","Six","Seven","Eight","Nine","Ten"]
z1 = Array{String}(undef,4,4)
for i in 1:4
    for j in 1:4
        z1[i,j] = txt[z[i,j]]
    end
end
println(z1)
heatmap(x,y,z1)
=#
