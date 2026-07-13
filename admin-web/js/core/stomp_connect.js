class StompConnect {

    constructor() {
        this.client = null;
    }

    connect(token, onConnect = null, onError = null) {

        const socket = new SockJS("http://localhost:8080/ws");

        this.client = Stomp.over(socket);

        // Tắt log của stomp
        this.client.debug = null;

        this.client.connect(
            {
                Authorization: `Bearer ${token}`
            },
            () => {
                console.log("✅ WebSocket Connected");
                onConnect?.();
            },
            error => {
                console.error("❌ WebSocket Error", error);
                onError?.(error);
            }
        );
    }

    subscribe(destination, callback) {

        if (!this.client || !this.client.connected) {
            console.warn("WebSocket chưa kết nối");
            return null;
        }

        return this.client.subscribe(destination, message => {
            callback(JSON.parse(message.body));
        });
    }

    publish(destination, body = {}) {

        if (!this.client || !this.client.connected) {
            return;
        }

        this.client.send(
            destination,
            {},
            JSON.stringify(body)
        );
    }

    disconnect() {

        if (this.client) {
            this.client.disconnect(() => {
                console.log("🔌 WebSocket Disconnected");
            });

            this.client = null;
        }
    }

    get connected() {
        return this.client && this.client.connected;
    }
}

export const stompConnect = new StompConnect();