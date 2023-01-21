using Plots

n = 27 # odd !
cmap = [colorant"white", colorant"black"]

# Basic grid
grid = ones(n,n)
for i in 2:n-1
  for j in 2:n-1 
    if j%2==0 && i%2==0 
      grid[i,j]=0
    end
  end
end

lRange = 2:2:n-1
nb=3

Plots.heatmap(grid, fill=true, c=cmap,xaxis=nothing,yaxis=nothing,legend=nothing,size=(600,600))


cmap = [colorant"black", colorant"white"] # I switch the array to get a color correspondence 
for i in 2:2:n
  for j in 2:2:n
    nb+=1
    grid[i, j] = nb
  end
end


# ? color
for i in 2:nb-1 
  push!(cmap, RGB(rand(),rand(),rand()))
end

# ? Enter and exit
enterRand = rand(lRange)
grid[enterRand, 1]=2
grid[enterRand, 2]=2

exitRand = rand(lRange)
grid[exitRand, n]=3
grid[exitRand, n-1]=3

Plots.heatmap(grid, fill=true, c=cmap,xaxis=nothing,yaxis=nothing,legend=nothing,size=(600,600))


# ? create labyrinthe
wOddRange = 3:2:n-2
wEvenRange = 2:2:n-1

wallRestHor = Array{Tuple{Int64, Int64},1}(undef, 0)  
wallRestVer = Array{Tuple{Int64, Int64},1}(undef, 0)

for i in wOddRange
  for j in wEvenRange
    push!(wallRestHor, (i, j))
    push!(wallRestVer, (j, i))
  end
end
    
print(wallRestHor[149][2])
function plotUpdate(XY)
  global grid, nb, wallRestHor, wallRestVer
  wallRand = (XY==0) ? rand(1:length(wallRestHor)) : rand(1:length(wallRestVer))
  ( (x, y), X, Y) = (XY==0) ? ( (wallRestHor[wallRand][1], wallRestHor[wallRand][2] ), 1, 0) : ( (wallRestVer[wallRand][1], wallRestVer[wallRand][2]), 0, 1) 

  wallSelect = grid[x, y]
  if wallSelect==1 && grid[x+X,y+Y]!=grid[x-X,y-Y]

    grid[x, y] = grid[x+X,y+Y]
    replace!(grid, grid[x+X,y+Y]=>grid[x-X,y-Y])
    nb-=1

    (XY==0) ? deleteat!(wallRestHor, wallRand) : deleteat!(wallRestVer, wallRand)

    Plots.heatmap(grid, fill=true, c=cmap,xaxis=nothing,yaxis=nothing,legend=nothing,size=(600,600))
  end
end

anim = @animate while nb-4>0
  if rand()>0.5 # Horizontal (X)
    plotUpdate(0)
  else # Vertical (Y)
    plotUpdate(1)
  end
end



# * If you want get the labyrinth 
# Plots.heatmap(grid, fill=true, c=cmap,xaxis=nothing,yaxis=nothing,legend=nothing,size=(600,600))
gif(anim, "animLabyrinth.gif",  fps = 30)


# ? Create the solving path
gridPath = zeros(n,n) # Here 0 is either a wall or a location more far than the exit
gridPath[enterRand, 1] = lengthPath = 1

xTemp = yTemp = 0
function continuePath(PM, XY, nbIntersection) # P(lus)M(oins) : 0 => + ; 1 => -
  global lengthPath, gridPath, xPath, yPath, intersection, xTemp, yTemp

  (X,Y) = (XY==0) ? (1, 0) : (0, 1)  
  sign = (PM==0) ? 1 : -1

  # I detect where are crossroads and look if the "path" go to an unknown path
  try
    if gridPath[xPath+sign*X, yPath+sign*Y]==0 && grid[xPath+sign*X, yPath+sign*Y]!=1
      if nbIntersection==0
        lengthPath+=1
        gridPath[xPath+sign*X, yPath+sign*Y]=lengthPath

        xTemp = xPath + sign*X
        yTemp = yPath + sign*Y
      else 
        push!(intersection, (xPath, yPath, lengthPath-1))
      end
      return true
    end
  catch
    return false
  end

  return false
end

xPath = enterRand
yPath = 1
intersection = Array{Tuple{Int64, Int64, Int64},1}(undef, 0)


while xPath!=exitRand || yPath!=n
  nbIntersection = 0
  for i in [(0,0), (0,1), (1,0), (1,1)]
    if continuePath(i[1], i[2], nbIntersection)
      nbIntersection+=1
    end
  end

  if nbIntersection==0 # If it took the wrong path, it goes back and starts from a crossroads
    xPath = intersection[1][1]
    yPath = intersection[1][2]
    lengthPath = intersection[1][3]
    popfirst!(intersection)
  else
    xPath = xTemp
    yPath = yTemp
  end
end

# * If you want know how the program find the path
# Plots.heatmap(gridPath, fill=true, c=cmap[1:2],xaxis=nothing,yaxis=nothing,legend=nothing)


xPathSolve = exitRand
yPathSolve = n

# I change values for colors setting
replace!(grid,grid[enterRand,1]=>2)
pathVal = grid[enterRand,1]+1
grid[exitRand,n] = pathVal

anim2 = @animate while lengthPath-1!=0
  global xPathSolve, yPathSolve, lengthPath
  lPath = findall(a->a==lengthPath-1, gridPath)
  for i in lPath
    if abs(xPathSolve-i[1])<2 && abs(yPathSolve-i[2])<2 # If the continuation of pathSolve is near of pathSolve that's means is the real continuation !
      lengthPath-=1
      xPathSolve = i[1]
      yPathSolve = i[2]

      grid[xPathSolve, yPathSolve] = pathVal
      break
    end
  end
  Plots.heatmap(grid, fill=true, c=cmap[1:3],xaxis=nothing,yaxis=nothing,legend=nothing)
end

# * If you want see the solving
# Plots.heatmap(grid, fill=true, c=cmap[1:3],xaxis=nothing,yaxis=nothing,legend=nothing)
gif(anim2, "animPathSolving.gif", fps = 10)
