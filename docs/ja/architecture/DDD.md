# Symfony を使用したドメイン駆動設計

> 🌍 **言語**: [English](../../en/architecture/DDD.md) | [Français](../../fr/architecture/DDD.md) | [日本語](../../ja/architecture/DDD.md)

## 目次

- [はじめに](#はじめに)
- [基本概念](#基本概念)
- [レイヤードアーキテクチャ](#レイヤードアーキテクチャ)
- [戦術的ビルディングブロック](#戦術的ビルディングブロック)
  - [エンティティ](#エンティティ)
  - [値オブジェクト](#値オブジェクト)
  - [集約](#集約)
  - [リポジトリ](#リポジトリ)
  - [ドメインサービス](#ドメインサービス)
  - [ドメインイベント](#ドメインイベント)
- [プロジェクト構造](#プロジェクト構造)
- [具体例](#具体例)
- [参考資料](#参考資料)

## はじめに

ドメイン駆動設計（DDD）は、ビジネスドメインの深い理解を重視するソフトウェア開発アプローチです。Symfony では、DDD を使用することで、ビジネスロジックがインフラストラクチャから明確に分離された保守性の高いアプリケーションを作成できます。

## 基本概念

### ユビキタス言語

開発者とドメインエキスパート間で同じ語彙を使用します。

```php
// ❌ 悪い例：技術的な語彙
class UserRecord { }
class OrderProcessor { }

// ✅ 良い例：ビジネス用語
class Customer { }
class Order { }
class OrderFulfillment { }
```

### 境界づけられたコンテキスト

各ビジネスコンテキストの境界を定義します。

```
src/
├── Sales/              # 販売コンテキスト
├── Inventory/          # 在庫コンテキスト
├── Shipping/           # 配送コンテキスト
└── Billing/            # 請求コンテキスト
```

## レイヤードアーキテクチャ

```
┌─────────────────────────────────────┐
│   Presentation Layer (UI/API)       │
│   Controllers, Forms, Serializers   │
├─────────────────────────────────────┤
│   Application Layer                 │
│   Use Cases, Commands, Queries      │
├─────────────────────────────────────┤
│   Domain Layer                      │
│   Entities, Value Objects, Services │
├─────────────────────────────────────┤
│   Infrastructure Layer              │
│   Repositories, External Services   │
└─────────────────────────────────────┘
```

## 戦術的ビルディングブロック

### エンティティ

時間を超えて永続する一意の識別子を持つオブジェクト。

```php
// src/Domain/Model/Order.php
namespace App\Domain\Model;

class Order
{
    private OrderId $id;
    private CustomerId $customerId;
    private OrderStatus $status;
    private \DateTimeImmutable $createdAt;
    private array $items = [];

    public function __construct(OrderId $id, CustomerId $customerId)
    {
        $this->id = $id;
        $this->customerId = $customerId;
        $this->status = OrderStatus::pending();
        $this->createdAt = new \DateTimeImmutable();
    }

    public function addItem(Product $product, Quantity $quantity): void
    {
        if ($this->status->isClosed()) {
            throw new \DomainException('Cannot add items to a closed order');
        }

        $this->items[] = new OrderItem($product->getId(), $quantity, $product->getPrice());
    }

    public function place(): void
    {
        if (empty($this->items)) {
            throw new \DomainException('Cannot place an empty order');
        }

        if (!$this->status->isPending()) {
            throw new \DomainException('Order has already been placed');
        }

        $this->status = OrderStatus::placed();
    }

    public function getTotalAmount(): Money
    {
        return array_reduce(
            $this->items,
            fn(Money $total, OrderItem $item) => $total->add($item->getSubtotal()),
            Money::zero()
        );
    }

    public function getId(): OrderId
    {
        return $this->id;
    }
}
```

### 値オブジェクト

独自の識別子を持たず、値によって定義される不変オブジェクト。

```php
// src/Domain/ValueObject/Money.php
namespace App\Domain\ValueObject;

final class Money
{
    private function __construct(
        private int $amount,      // セント単位
        private string $currency
    ) {
        if ($amount < 0) {
            throw new \InvalidArgumentException('Amount cannot be negative');
        }
    }

    public static function fromAmount(float $amount, string $currency): self
    {
        return new self((int) round($amount * 100), $currency);
    }

    public static function zero(string $currency = 'EUR'): self
    {
        return new self(0, $currency);
    }

    public function add(Money $other): self
    {
        $this->assertSameCurrency($other);
        return new self($this->amount + $other->amount, $this->currency);
    }

    public function multiply(int $factor): self
    {
        return new self($this->amount * $factor, $this->currency);
    }

    public function equals(Money $other): bool
    {
        return $this->amount === $other->amount
            && $this->currency === $other->currency;
    }

    public function getAmount(): float
    {
        return $this->amount / 100;
    }

    public function getCurrency(): string
    {
        return $this->currency;
    }

    private function assertSameCurrency(Money $other): void
    {
        if ($this->currency !== $other->currency) {
            throw new \InvalidArgumentException('Cannot operate on different currencies');
        }
    }
}

// src/Domain/ValueObject/Email.php
final class Email
{
    private function __construct(
        private string $value
    ) {
        if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
            throw new \InvalidArgumentException("Invalid email: $value");
        }
    }

    public static function fromString(string $email): self
    {
        return new self(strtolower(trim($email)));
    }

    public function getValue(): string
    {
        return $this->value;
    }

    public function equals(Email $other): bool
    {
        return $this->value === $other->value;
    }

    public function __toString(): string
    {
        return $this->value;
    }
}

// src/Domain/ValueObject/OrderId.php
final class OrderId
{
    private function __construct(
        private string $value
    ) {}

    public static function generate(): self
    {
        return new self(\Symfony\Component\Uid\Uuid::v4()->toRfc4122());
    }

    public static function fromString(string $id): self
    {
        return new self($id);
    }

    public function getValue(): string
    {
        return $this->value;
    }

    public function equals(OrderId $other): bool
    {
        return $this->value === $other->value;
    }
}
```

### 集約

データの整合性のために単一のユニットとして扱われるオブジェクトのグループ。

```php
// src/Domain/Model/Order.php (集約ルート)
namespace App\Domain\Model;

class Order
{
    private OrderId $id;
    private array $items = [];  // 関連エンティティのコレクション

    // Orderはアイテムを変更する唯一のエントリーポイント
    public function addItem(Product $product, Quantity $quantity): void
    {
        // アイテムを追加するためのビジネスルール
        $existingItem = $this->findItem($product->getId());

        if ($existingItem) {
            $existingItem->increaseQuantity($quantity);
        } else {
            $this->items[] = new OrderItem(
                $product->getId(),
                $quantity,
                $product->getPrice()
            );
        }
    }

    public function removeItem(ProductId $productId): void
    {
        $this->items = array_filter(
            $this->items,
            fn(OrderItem $item) => !$item->getProductId()->equals($productId)
        );
    }

    // アイテムは外部から直接変更できない
    public function getItems(): array
    {
        return $this->items;
    }

    private function findItem(ProductId $productId): ?OrderItem
    {
        foreach ($this->items as $item) {
            if ($item->getProductId()->equals($productId)) {
                return $item;
            }
        }
        return null;
    }
}

// src/Domain/Model/OrderItem.php (集約内のエンティティ)
class OrderItem
{
    private ProductId $productId;
    private Quantity $quantity;
    private Money $unitPrice;

    public function __construct(ProductId $productId, Quantity $quantity, Money $unitPrice)
    {
        $this->productId = $productId;
        $this->quantity = $quantity;
        $this->unitPrice = $unitPrice;
    }

    public function increaseQuantity(Quantity $additional): void
    {
        $this->quantity = $this->quantity->add($additional);
    }

    public function getSubtotal(): Money
    {
        return $this->unitPrice->multiply($this->quantity->getValue());
    }

    public function getProductId(): ProductId
    {
        return $this->productId;
    }
}
```

### リポジトリ

集約にアクセスするためのインターフェース。

```php
// src/Domain/Repository/OrderRepositoryInterface.php
namespace App\Domain\Repository;

interface OrderRepositoryInterface
{
    public function save(Order $order): void;
    public function findById(OrderId $id): ?Order;
    public function findByCustomer(CustomerId $customerId): array;
    public function nextIdentity(): OrderId;
}

// src/Infrastructure/Persistence/DoctrineOrderRepository.php
namespace App\Infrastructure\Persistence;

use App\Domain\Model\Order;
use App\Domain\Repository\OrderRepositoryInterface;
use Doctrine\ORM\EntityManagerInterface;

class DoctrineOrderRepository implements OrderRepositoryInterface
{
    public function __construct(
        private EntityManagerInterface $em
    ) {}

    public function save(Order $order): void
    {
        $this->em->persist($order);
        $this->em->flush();
    }

    public function findById(OrderId $id): ?Order
    {
        return $this->em->getRepository(Order::class)->find($id->getValue());
    }

    public function findByCustomer(CustomerId $customerId): array
    {
        return $this->em->getRepository(Order::class)
            ->findBy(['customerId' => $customerId->getValue()]);
    }

    public function nextIdentity(): OrderId
    {
        return OrderId::generate();
    }
}
```

### ドメインサービス

エンティティに自然に適合しないビジネスロジックを含むサービス。

```php
// src/Domain/Service/PricingService.php
namespace App\Domain\Service;

class PricingService
{
    public function __construct(
        private TaxCalculator $taxCalculator,
        private DiscountPolicy $discountPolicy
    ) {}

    public function calculateFinalPrice(Order $order, Customer $customer): Money
    {
        $subtotal = $order->getTotalAmount();

        // 割引を適用
        $discount = $this->discountPolicy->calculateDiscount($customer, $subtotal);
        $afterDiscount = $subtotal->subtract($discount);

        // 税金を計算
        $tax = $this->taxCalculator->calculateTax($afterDiscount, $customer->getCountry());

        return $afterDiscount->add($tax);
    }
}

// src/Domain/Service/OrderNumberGenerator.php
class OrderNumberGenerator
{
    public function generate(): string
    {
        return sprintf(
            'ORD-%s-%s',
            date('Ymd'),
            strtoupper(substr(uniqid(), -8))
        );
    }
}
```

### ドメインイベント

重要なビジネス事実を表すイベント。

```php
// src/Domain/Event/OrderPlacedEvent.php
namespace App\Domain\Event;

class OrderPlacedEvent
{
    public function __construct(
        private OrderId $orderId,
        private CustomerId $customerId,
        private Money $totalAmount,
        private \DateTimeImmutable $occurredAt
    ) {}

    public function getOrderId(): OrderId
    {
        return $this->orderId;
    }

    public function getCustomerId(): CustomerId
    {
        return $this->customerId;
    }

    public function getTotalAmount(): Money
    {
        return $this->totalAmount;
    }

    public function getOccurredAt(): \DateTimeImmutable
    {
        return $this->occurredAt;
    }
}

// 集約内でイベントを記録
class Order
{
    private array $domainEvents = [];

    public function place(): void
    {
        // ... バリデーション

        $this->status = OrderStatus::placed();
        $this->recordEvent(new OrderPlacedEvent(
            $this->id,
            $this->customerId,
            $this->getTotalAmount(),
            new \DateTimeImmutable()
        ));
    }

    private function recordEvent(object $event): void
    {
        $this->domainEvents[] = $event;
    }

    public function pullDomainEvents(): array
    {
        $events = $this->domainEvents;
        $this->domainEvents = [];
        return $events;
    }
}
```

## プロジェクト構造

```
src/
├── Application/
│   ├── Command/
│   │   ├── PlaceOrderCommand.php
│   │   └── PlaceOrderHandler.php
│   ├── Query/
│   │   ├── GetOrderQuery.php
│   │   └── GetOrderHandler.php
│   └── DTO/
│       └── OrderDTO.php
├── Domain/
│   ├── Model/
│   │   ├── Order.php
│   │   ├── OrderItem.php
│   │   └── Customer.php
│   ├── ValueObject/
│   │   ├── OrderId.php
│   │   ├── Money.php
│   │   └── Email.php
│   ├── Repository/
│   │   └── OrderRepositoryInterface.php
│   ├── Service/
│   │   └── PricingService.php
│   └── Event/
│       └── OrderPlacedEvent.php
├── Infrastructure/
│   ├── Persistence/
│   │   ├── DoctrineOrderRepository.php
│   │   └── Mapping/
│   │       └── Order.orm.xml
│   ├── Messaging/
│   │   └── RabbitMQEventPublisher.php
│   └── External/
│       └── StripePaymentGateway.php
└── Presentation/
    ├── Controller/
    │   └── OrderController.php
    └── Form/
        └── PlaceOrderType.php
```

## 具体例

### DDD を使用した CQRS

```php
// コマンド（変更）
class PlaceOrderCommand
{
    public function __construct(
        public readonly string $customerId,
        public readonly array $items
    ) {}
}

class PlaceOrderHandler
{
    public function __construct(
        private OrderRepositoryInterface $orderRepository,
        private CustomerRepositoryInterface $customerRepository,
        private ProductRepositoryInterface $productRepository,
        private EventDispatcherInterface $eventDispatcher
    ) {}

    public function handle(PlaceOrderCommand $command): OrderId
    {
        $customerId = CustomerId::fromString($command->customerId);
        $customer = $this->customerRepository->findById($customerId);

        if (!$customer) {
            throw new \DomainException('Customer not found');
        }

        $order = new Order(
            $this->orderRepository->nextIdentity(),
            $customerId
        );

        foreach ($command->items as $item) {
            $product = $this->productRepository->findById(
                ProductId::fromString($item['productId'])
            );

            $order->addItem(
                $product,
                Quantity::fromInt($item['quantity'])
            );
        }

        $order->place();
        $this->orderRepository->save($order);

        // ドメインイベントを公開
        foreach ($order->pullDomainEvents() as $event) {
            $this->eventDispatcher->dispatch($event);
        }

        return $order->getId();
    }
}

// クエリ（読み取り）
class GetOrderQuery
{
    public function __construct(
        public readonly string $orderId
    ) {}
}

class GetOrderHandler
{
    public function __construct(
        private OrderRepositoryInterface $orderRepository
    ) {}

    public function handle(GetOrderQuery $query): OrderDTO
    {
        $order = $this->orderRepository->findById(
            OrderId::fromString($query->orderId)
        );

        if (!$order) {
            throw new \DomainException('Order not found');
        }

        return OrderDTO::fromOrder($order);
    }
}
```

### 仕様パターン

```php
// src/Domain/Specification/CustomerCanPlaceOrderSpecification.php
interface SpecificationInterface
{
    public function isSatisfiedBy(Customer $customer): bool;
}

class CustomerCanPlaceOrderSpecification implements SpecificationInterface
{
    public function isSatisfiedBy(Customer $customer): bool
    {
        return $customer->isActive()
            && !$customer->hasUnpaidOrders()
            && $customer->getCreditLimit()->isGreaterThan(Money::zero());
    }
}

class MinimumAgeSpecification implements SpecificationInterface
{
    public function __construct(
        private int $minimumAge
    ) {}

    public function isSatisfiedBy(Customer $customer): bool
    {
        return $customer->getAge() >= $this->minimumAge;
    }
}

// 使用例
if (!$specification->isSatisfiedBy($customer)) {
    throw new \DomainException('Customer cannot place order');
}
```

## 参考資料

- [SOLID 原則](./SOLID.md)
- [デザインパターン](./DesignPatterns.md)
- [リファクタリングのベストプラクティス](./HowToRefactoBestPractices.md)
- 📚 [Domain-Driven Design - Eric Evans](https://www.domainlanguage.com/)
- 📚 [Implementing Domain-Driven Design - Vaughn Vernon](https://www.oreilly.com/library/view/implementing-domain-driven-design/9780133039900/)
- 📚 [Doctrine ORM Best Practices](https://www.doctrine-project.org/projects/doctrine-orm/en/current/reference/best-practices.html)
