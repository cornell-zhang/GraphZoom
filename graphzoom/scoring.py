from __future__ import print_function
import json
import numpy as np

from networkx.readwrite import json_graph

def run_regression(train_embeds, train_labels, test_embeds, test_labels):
    from sklearn.linear_model import SGDClassifier
    from sklearn.dummy import DummyClassifier
    from sklearn.metrics import f1_score
    from sklearn.linear_model import LogisticRegression
    dummy = DummyClassifier()
    dummy.fit(train_embeds, train_labels)
    log = LogisticRegression(solver='liblinear', multi_class='ovr')
    log.fit(train_embeds, train_labels)
    print("Test scores")
    print("Micro F1 score: {}".format(f1_score(test_labels, log.predict(test_embeds), average="micro")))
    print("Train scores")
    print("Micro F1 score: {}".format(f1_score(train_labels, log.predict(train_embeds), average="micro")))
    print("Random baseline")
    print("Micro F1 score: {}".format(f1_score(test_labels, dummy.predict(test_embeds), average="micro")))


def lr(dataset_dir, data_dir, dataset):
    print("%%%%%% Starting Evaluation %%%%%%")
    print("Loading data...")
    G = json_graph.node_link_graph(json.load(open(dataset_dir + "/{}-G.json".format(dataset))))
    labels = json.load(open(dataset_dir + "/{}-class_map.json".format(dataset)))
    
    train_ids = [n for n in G.nodes() if not G.node[n]['val'] and not G.node[n]['test']]
    test_ids = [n for n in G.nodes() if G.node[n]['test']]
    train_labels = [labels[str(i)] for i in train_ids]
    test_labels = [labels[str(i)] for i in test_ids]
    
    embeds = np.load(data_dir)
    train_embeds = embeds[[id for id in train_ids]] 
    test_embeds = embeds[[id for id in test_ids]] 
    print("Running regression..")
    run_regression(train_embeds, train_labels, test_embeds, test_labels)
