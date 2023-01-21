using PlotlyJS
using Plots
using ImageMagick


function mesh_box(l,w,h,x,y,z,c)
    PlotlyJS.mesh3d(
        x = [x, x+l, x,   x+l, x,   x+l, x,   x+l],
        y = [y, y,   y+w, y+w, y,   y,   y+w, y+w],
        z = [z, z,   z,   z,   z+h, z+h, z+h, z+h],
        i = [0, 0, 0, 0, 0, 0, 7, 7, 7, 7, 7, 7],
        j = [3, 3, 5, 5, 6, 6, 3, 3, 5, 5, 6, 6],
        k = [1, 2, 1, 4, 2, 4, 1, 2, 1, 4, 2, 4],
        color = c,
    )
end

function colorCmap(a,b,c, alpha=0.2)
    return "rgba("*string(a)*","*string(b)*","*string(c)*","*string(alpha)*")"
end

iImg = 1
function saveImg()
    global iImg

    filename = "img3d/"*"$(lpad(iImg, 3, "0"))"*".png"
    PlotlyJS.savefig(p, filename)
    iImg+=1
end

p = PlotlyJS.plot()
cmap = [ 
    colorCmap(255,255,255),
    colorCmap(0,0,0,0)
]

# ? grid basic
n=7 # Odd
for i in 1:n
    for j in 1:n
        for l in 1:n
            if i==1 || i==n || j==1 || j==n || l==1 || l==n || i%2==1 || j%2==1 || l%2==1
                PlotlyJS.addtraces!(p, mesh_box(1, 1, 1, i, j, l, cmap[2]))
            else
                PlotlyJS.addtraces!(p, mesh_box(1, 1, 1, i, j, l, cmap[1]))
            end
        end
    end
end                
saveImg()


# ? color
lCubeColor = Int64[]
indice = n^2+n+2
for i in 2:2:n
    for j in 2:2:n
        for l in 2:2:n
            push!(cmap, colorCmap(rand(0:255), rand(0:255), rand(0:255)))
            push!(lCubeColor, indice)
            indice+=2
        end
        indice+=n+1
    end
    indice+=n^2+n
end

PlotlyJS.restyle!(p, lCubeColor, color=cmap[3:end] )
p
saveImg()

# ? plot in grid
grid = ones(n,n,n)
for (i,e) in enumerate(lCubeColor)
    grid[e] = i+1
end

nb = ( (n+1)/2 - 1)^3


# ? enter & exit
lRange = 2:2:n-1
enterRandX = rand(lRange)
enterRandZ = rand(lRange)
nb+=1
grid[enterRandX, 1, enterRandZ] = nb
grid[enterRandX, 2, enterRandZ] = nb

push!(cmap, colorCmap(rand(0:255), rand(0:255), rand(0:255)))
iEnter = (enterRandZ-1)*n^2+enterRandX
PlotlyJS.restyle!(p, [iEnter, iEnter+n], color=cmap[end])

exitRandX = rand(lRange)
exitRandZ = rand(lRange)
nb+=1
grid[exitRandX, n, exitRandZ] = nb
grid[exitRandX, n-1, exitRandZ] = nb

push!(cmap, colorCmap(rand(0:255), rand(0:255), rand(0:255)))
iExit = (exitRandZ-1)*n^2 + exitRandX + n*(n-1) 
PlotlyJS.restyle!(p, [iExit, iExit-n], color=cmap[end] )

saveImg()
p
# ? create labyrinthe
# TODO : Update too
wOddRange = 3:2:n-2
wEvenRange = 2:2:n-1



function plotUpdate(XYZ)
    global grid, nb

    x,y,z = rand(wEvenRange),  rand(wEvenRange),  rand(wEvenRange)
    X = Y = Z = 0

    if XYZ==0
        x=rand(wOddRange)
        X=1
    elseif XYZ==1
        y=rand(wOddRange)
        Y=1
    else
        z=rand(wOddRange)
        Z=1
    end

    if grid[x, y, z]==1 && grid[x+X,y+Y,z+Z]!=grid[x-X,y-Y,z-Z]
        grid[x, y, z] = grid[x-X, y-Y, z-Z]
        
        iCartesian = findall(a->a==Int64(grid[x+X, y+Y, z+Z]), grid)
        lCubeReplace = [ (i[3]-1)*n^2 + (i[2]-1)*n + i[1] for i in iCartesian]
        
        push!(lCubeReplace, (z-1)*n^2 + (y-1)*n + x )
        
        e = Int64(grid[x-X, y-Y, z-Z])
        PlotlyJS.restyle!(p, lCubeReplace, color=cmap[e+1] )
        
        replace!(grid, grid[x+X,y+Y,z+Z]=>grid[x-X,y-Y,z-Z])
        nb-=1

        # save image
        saveImg()

    end 
end

while nb-4>0 || length(unique(grid))>2 # || length(unique(grid))>2 is not necessary but julia is strange... so to be sure, I wrote this
    choiceWall = rand()
    if choiceWall>0.666 # X
        plotUpdate(0)
    elseif choiceWall>0.333 # Y
        plotUpdate(1)
    else # Z
        plotUpdate(2)
    end
end
p

# To pause the gif's end
for i in 1:10
    saveImg()
end

anim = @animate for img in readdir("img3d/")
    Plots.plot(ImageMagick.load("img3d/"*img),xaxis=nothing,yaxis=nothing,legend=nothing,size=(600,600))
end
gif(anim, "animLabyrinth3D.gif", fps = 15)



# # ? Solving path
# gridPath = zeros(n,n,n) # Here 0 is either a wall or a location more far than the exit
# gridPath[enterRandX, 1, enterRandZ] = lengthPath = 1

# xTemp = yTemp = zTemp = 0

# function continuePath(PM, XYZ, nbIntersection) # P(lus)M(oins) : 0 => + ; 1 => -
#     global lengthPath, gridPath, xPath, yPath, zPath, intersection, xTemp, yTemp
#     X = Y = Z = 0
#     if XYZ == 0
#         X=1
#     elseif XYZ == 1
#         Y=1
#     else
#         Z=1
#     end
#     sign = (PM==0) ? 1 : -1
  
#     # I detect where are crossroads and look if the "path" go to an unknown path
#     try
#       if gridPath[xPath+sign*X, yPath+sign*Y, zPath+sign*Z]==0 && grid[xPath+sign*X, yPath+sign*Y, zPath+sign*Z]!=1
#         if nbIntersection==0
#           lengthPath+=1
#           gridPath[xPath+sign*X, yPath+sign*Y, zPath+sign*Z]=lengthPath
  
#           xTemp = xPath + sign*X
#           yTemp = yPath + sign*Y
#           zTemp = zPath + sign*Z
#         else 
#           push!(intersection, (xPath, yPath, zPath, lengthPath-1))
#         end
#         return true
#       end
#     catch
#       return false
#     end
  
#     return false
#   end

#   xPath = enterRandX
#   yPath = 1
#   zPath = enterRandZ
#   intersection = Array{Tuple{Int64, Int64, Int64, Int64},1}(undef, 0)

  
# while xPath!=exitRandX || yPath!=n || zPath!=exitRandZ
#     nbIntersection = 0
#     for i in [(0,0,0), (0,0,1), (0,1,0), (0,1,1), (1,0,0), (1,0,1), (1,1,0), (1,1,1)]
#         if continuePath(i[1], i[2], i[3] nbIntersection)
#         nbIntersection+=1
#         end
#     end

#     if nbIntersection==0 # If it took the wrong path, it goes back and starts from a crossroads
#         xPath = intersection[1][1]
#         yPath = intersection[1][2]
#         yPath = intersection[1][3]
#         lengthPath = intersection[1][4]
#         popfirst!(intersection)
#     else
#         xPath = xTemp
#         yPath = yTemp
#         zPath = zTemp
#     end
# end

# xPathSolve = exitRand
# yPathSolve = n

  























