//Parameters
Vertex[] vertices;
Polygon[] polys;
int N = 5;
float rMin = 0.25, rMax = 0.75;
float t = 0;

void setup()
{
  size(2000, 2000);
  background(224, 211, 175);
  noFill();
  stroke(112, 66, 30, 25);
  blendMode(MULTIPLY);

  //Create starting polygon
  polys = new Polygon[1];
  vertices = new Vertex[N];
  for (int i = 0; i < N; i++)
  {
    vertices[i] = new Vertex(PVector.add(PVector.fromAngle(i * TWO_PI / N - PI / 2).mult(random(950, 950)), new PVector(width / 2, height / 2)), i);
  }
  polys[0] = new Polygon(vertices, 0);

  //Recursively divide polygons 
  while (polys[0].depth < 6)
    polys = (Polygon[]) concat((Polygon[]) subset(polys, 1), polys[0].divide());

  //Extract link information from polygons
  for (Polygon p : polys)
  {
    p.getLinks();
  }
}

void draw()
{
  for (Vertex v : vertices)
  {
    v.computeSpeed();
  }
  for (Vertex v : vertices)
  {
    v.move();
    v.render();
  }
  t += 0.02;

  //Stop condition
  if (frameCount == 100)
  {
    noLoop();
    println("done");
    saveFrame("image.png");
  }
}

class Vertex
{
  PVector position, speed;
  Vertex[] neighbors;
  int index;

  Vertex(PVector p, int i)
  {
    position = p;
    index = i;
    neighbors = new Vertex[0];
    speed = new PVector(0, 0);
  }

  void addNeighbor(Vertex v)
  {
    boolean toAdd = true;
    //check if not already a neighbor
    for (Vertex n : neighbors)
    {
      if (n.index == v.index)
      {
        toAdd = false;
      }
    }
    if (toAdd)
    {
      neighbors = (Vertex[]) append(neighbors, v);
    }
  }

  void render()
  {
    for (Vertex v : neighbors)
    {
      //only draw a line if index of neighbor is > to own index to avoid duplicates
      if (index < v.index)
      {
        line(position.x, position.y, v.position.x, v.position.y);
      }
    }
  }

  void computeSpeed()
  {
    speed = new PVector(0, 0);
    //d = sum of distances to neighbors
    float d = 0;
    for (Vertex v : neighbors)
    {
      d += dist(position.x, position.y, v.position.x, v.position.y);
    }

    //sprinkle in a bit of noise
    d *= noise(position.x / 50, position.y / 50, t) + 0.5;

    //spring like interaction
    for (Vertex v : neighbors)
    {
      PVector force = PVector.sub(v.position, position);
      force.setMag(0.01 * (d - force.mag()));
      speed.add(force);
    }
  }

  void move()
  {
    position.add(speed);
  }
}

class Polygon
{
  Vertex[] points;
  int depth;

  Polygon(Vertex[] p, int d)
  {
    points = p;
    depth = d;
  }

  Polygon[] divide()
  {
    Polygon[] newPolys = new Polygon[points.length + 1];
    Vertex[] midPoints = new Vertex[points.length];
    Vertex[] centerPoints = new Vertex[points.length];
    PVector barycenter = new PVector(0, 0);
    for (Vertex v : points)
    {
      barycenter.add(v.position);
    }
    barycenter.div(points.length);

    //create points located on the sides of the polygon
    for (int i = 0; i < points.length; i++)
    {
      float r = random(rMin, rMax);
      PVector p = PVector.add(PVector.mult(points[i].position, r), PVector.mult(points[(i < points.length - 1)? i + 1 : 0].position, 1 - r));
      boolean added = false;
      for (Vertex v : vertices)
      {
        //check if point already exists
        if (PVector.sub(p, v.position).magSq() < 0.001)
        {
          midPoints[i] = v;
          added = true;
          break;
        }
      }
      if (!added)
      {
        midPoints[i] = new Vertex(p, vertices.length);
        vertices = (Vertex[]) append(vertices, midPoints[i]);
      }
    }

    //create points inside the polygon
    for (int i = 0; i <  points.length; i++)
    {
      float r = random(rMin, rMax);
      PVector p = PVector.add(PVector.mult(midPoints[i].position, r), PVector.mult(barycenter, 1 - r));
      //no need to check for existence, it can't happen
      centerPoints[i] = new Vertex(p, vertices.length);
      vertices = (Vertex[]) append(vertices, centerPoints[i]);
    }

    //create new polygons from new points
    for (int i = 0; i < newPolys.length - 1; i++)
    {
      Vertex[] a = {points[i], midPoints[i], centerPoints[i], centerPoints[(i > 0)? i - 1 : points.length - 1], midPoints[(i > 0)? i - 1 : points.length - 1]};
      newPolys[i] = new Polygon(a, depth + 1);
    }
    newPolys[newPolys.length - 1] = new Polygon(centerPoints, depth + 1);
    return newPolys;
  }

  void getLinks()
  {
    for (int  i = 0; i < points.length; i++)
    {
      points[i].addNeighbor(points[(i < points.length - 1)? i + 1 : 0]);
      points[i].addNeighbor(points[(i > 0)? i - 1 : points.length - 1]);
    }
  }
}
