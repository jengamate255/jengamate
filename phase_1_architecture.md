graph TD
    subgraph "Quotation & Order"
        A[QuotationReviewScreen] -->|Confirm Quote| B(DatabaseService);
        B -->|Generates Order| C(OrderModel);
        C -->|Status: PendingPayment| D[OrderDetailsScreen];
    end

    subgraph "Payment"
        E[PaymentScreen] -->|Upload Proof| F(DatabaseService);
        F -->|Updates| G(PaymentModel);
        F -->|Updates| C;
        C -->|Status: Partially/Fully Paid| D;
    end

    subgraph "Chat"
        H[InquiryDetailsScreen] -->|Chat| I[ChatScreen];
        D -->|Chat| I;
        I -->|Send/Receive| J(DatabaseService);
        J -->|R/W| K(MessageModel);
    end

    subgraph "Data Integrity"
        C -->|isLocked| D;
    end

    style A fill:#f9f,stroke:#333,stroke-width:2px
    style E fill:#f9f,stroke:#333,stroke-width:2px
    style H fill:#f9f,stroke:#333,stroke-width:2px
    style I fill:#f9f,stroke:#333,stroke-width:2px