#include "graph.h"

int main(void) {
    GRAPH graph = { 0 };
    char storage[64];
    void* first;
    void* second;

    graph.polygon_opaque_thaga.tha.tail_p = storage + sizeof(storage);

    first = GRAPH_ALLOC(&graph, 16);
    if (first != storage + 48) {
        return 1;
    }

    second = GRAPH_ALLOC(&graph, 8);
    if (second != storage + 40) {
        return 2;
    }

    if (graph.polygon_opaque_thaga.tha.tail_p != storage + 40) {
        return 3;
    }

    return 0;
}
