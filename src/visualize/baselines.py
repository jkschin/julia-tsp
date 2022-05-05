import pickle
import plotly.express as px
import plotly.graph_objects as go
import os


def read_data(filename):
    data = pickle.load(open(filename, "rb"))
    data = [i for i in data if i[1] != 1e+100] 
    return data


def add_trajectory(fig, data, tsp_name):
    x = list(map(lambda x: x[0], data))
    y = list(map(lambda x: x[1], data))
    fig.add_trace(
                go.Scatter(
                    name=tsp_name,
                    x=x,
                    y=y,
                    opacity=1,
                    mode="lines",
                    line=dict(width=1),
                    showlegend=True))


if __name__ == "__main__":
    fig = go.Figure()
    folder = "results/pickles"
    filenames = os.listdir(folder)
    for filename in filenames:
        data = read_data(os.path.join(folder, filename))
        if len(data) != 0:
            print(filename, data[-1])
        add_trajectory(fig, data, filename)
    print("Writing Image...")
    fig.write_image("results/plots/trajectory_plot.png")
