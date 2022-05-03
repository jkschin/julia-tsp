

def tsp_instance_parser(filename):
    f = open(filename, "r")
    coords = []
    for i in range(5):
        f.readline()
    f.readline()
    for line in f:
        if line == "EOF\n":
            break
        node_idx, x, y = line.split(" ")
        coord = [x, y]
        coord = [float(i) for i in coord]
        coords.append(coord)
    return coords


if __name__ == "__main__":
    coords = tsp_instance_parser("tsp_instances/u2319.tsp")