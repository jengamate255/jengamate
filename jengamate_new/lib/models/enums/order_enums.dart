import 'package:flutter/material.dart';

enum OrderStatus {
  pending,
  processing,
  completed,
  cancelled,
  onHold,
  shipped,
  delivered,
  returned,
  refunded,
  partiallyRefunded,
  awaitingPayment,
  paymentFailed,
  disputed,
  draft,
  quoted,
  accepted,
  rejected,
  invoiced,
  paid,
  partiallyPaid,
  overdue,
  archived,
  active,
  inactive,
  underReview,
  approved,
  denied,
  onDelivery,
  readyForPickup,
  pickupCompleted,
  rescheduled,
  onRoute,
  atLocation,
  loading,
  unloading,
  inspection,
  maintenance,
  breakdown,
  repaired,
  dispatched,
  assigned,
  unassigned,
  onSite,
  offSite,
  onHoldCustomer,
  onHoldSupplier,
  onHoldInternal,
  escalated,
  resolved,
  closed,
  reopened,
  verified,
  unverified,
  pendingApproval,
  approvedByCustomer,
  rejectedByCustomer,
  approvedBySupplier,
  rejectedBySupplier,
  pendingConfirmation,
  confirmed,
  awaitingConfirmation,
  confirmationRejected,
  scheduled,
  inProgress,
  paused,
  stopped,
  failed,
  success,
  warning,
  info,
  debug,
  trace,
  critical,
  alert,
  emergency,
  notice,
  verbose,
  silent,
  unknown,
  pendingPayment, // New status
  fullyPaid, // New status
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.onHold:
        return 'On Hold';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.returned:
        return 'Returned';
      case OrderStatus.refunded:
        return 'Refunded';
      case OrderStatus.partiallyRefunded:
        return 'Partially Refunded';
      case OrderStatus.awaitingPayment:
        return 'Awaiting Payment';
      case OrderStatus.paymentFailed:
        return 'Payment Failed';
      case OrderStatus.disputed:
        return 'Disputed';
      case OrderStatus.draft:
        return 'Draft';
      case OrderStatus.quoted:
        return 'Quoted';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.rejected:
        return 'Rejected';
      case OrderStatus.invoiced:
        return 'Invoiced';
      case OrderStatus.paid:
        return 'Paid';
      case OrderStatus.partiallyPaid:
        return 'Partially Paid';
      case OrderStatus.overdue:
        return 'Overdue';
      case OrderStatus.archived:
        return 'Archived';
      case OrderStatus.active:
        return 'Active';
      case OrderStatus.inactive:
        return 'Inactive';
      case OrderStatus.underReview:
        return 'Under Review';
      case OrderStatus.approved:
        return 'Approved';
      case OrderStatus.denied:
        return 'Denied';
      case OrderStatus.onDelivery:
        return 'On Delivery';
      case OrderStatus.readyForPickup:
        return 'Ready For Pickup';
      case OrderStatus.pickupCompleted:
        return 'Pickup Completed';
      case OrderStatus.rescheduled:
        return 'Rescheduled';
      case OrderStatus.onRoute:
        return 'On Route';
      case OrderStatus.atLocation:
        return 'At Location';
      case OrderStatus.loading:
        return 'Loading';
      case OrderStatus.unloading:
        return 'Unloading';
      case OrderStatus.inspection:
        return 'Inspection';
      case OrderStatus.maintenance:
        return 'Maintenance';
      case OrderStatus.breakdown:
        return 'Breakdown';
      case OrderStatus.repaired:
        return 'Repaired';
      case OrderStatus.dispatched:
        return 'Dispatched';
      case OrderStatus.assigned:
        return 'Assigned';
      case OrderStatus.unassigned:
        return 'Unassigned';
      case OrderStatus.onSite:
        return 'On Site';
      case OrderStatus.offSite:
        return 'Off Site';
      case OrderStatus.onHoldCustomer:
        return 'On Hold (Customer)';
      case OrderStatus.onHoldSupplier:
        return 'On Hold (Supplier)';
      case OrderStatus.onHoldInternal:
        return 'On Hold (Internal)';
      case OrderStatus.escalated:
        return 'Escalated';
      case OrderStatus.resolved:
        return 'Resolved';
      case OrderStatus.closed:
        return 'Closed';
      case OrderStatus.reopened:
        return 'Reopened';
      case OrderStatus.verified:
        return 'Verified';
      case OrderStatus.unverified:
        return 'Unverified';
      case OrderStatus.pendingApproval:
        return 'Pending Approval';
      case OrderStatus.approvedByCustomer:
        return 'Approved By Customer';
      case OrderStatus.rejectedByCustomer:
        return 'Rejected By Customer';
      case OrderStatus.approvedBySupplier:
        return 'Approved By Supplier';
      case OrderStatus.rejectedBySupplier:
        return 'Rejected By Supplier';
      case OrderStatus.pendingConfirmation:
        return 'Pending Confirmation';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.awaitingConfirmation:
        return 'Awaiting Confirmation';
      case OrderStatus.confirmationRejected:
        return 'Confirmation Rejected';
      case OrderStatus.scheduled:
        return 'Scheduled';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.paused:
        return 'Paused';
      case OrderStatus.stopped:
        return 'Stopped';
      case OrderStatus.failed:
        return 'Failed';
      case OrderStatus.success:
        return 'Success';
      case OrderStatus.warning:
        return 'Warning';
      case OrderStatus.info:
        return 'Info';
      case OrderStatus.debug:
        return 'Debug';
      case OrderStatus.trace:
        return 'Trace';
      case OrderStatus.critical:
        return 'Critical';
      case OrderStatus.alert:
        return 'Alert';
      case OrderStatus.emergency:
        return 'Emergency';
      case OrderStatus.notice:
        return 'Notice';
      case OrderStatus.verbose:
        return 'Verbose';
      case OrderStatus.silent:
        return 'Silent';
      case OrderStatus.unknown:
        return 'Unknown';
      case OrderStatus.pendingPayment:
        return 'Pending Payment';
      case OrderStatus.fullyPaid:
        return 'Fully Paid';
    }
  }

  String get value => name;

  Color get color {
    switch (this) {
      case OrderStatus.pending:
      case OrderStatus.awaitingPayment:
      case OrderStatus.pendingPayment:
      case OrderStatus.underReview:
        return Colors.orange;
      case OrderStatus.processing:
      case OrderStatus.inProgress:
      case OrderStatus.onRoute:
      case OrderStatus.shipped:
        return Colors.blue;
      case OrderStatus.completed:
      case OrderStatus.delivered:
      case OrderStatus.paid:
      case OrderStatus.fullyPaid:
      case OrderStatus.success:
        return Colors.green;
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
      case OrderStatus.paymentFailed:
      case OrderStatus.failed:
      case OrderStatus.denied:
        return Colors.red;
      case OrderStatus.partiallyPaid:
        return Colors.lightBlue;
      case OrderStatus.refunded:
      case OrderStatus.partiallyRefunded:
        return Colors.purple;
      case OrderStatus.onHold:
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}

enum OrderType {
  product,
  service,
  standard,
  urgent,
  bulk,
  quotation,
  rfq,
  custom,
  subscription,
  rental,
  lease,
  warranty,
  support,
  consultation,
  training,
  installation,
  repair,
  maintenance,
  delivery,
  pickup,
  returned,
  exchange,
  refund,
  credit,
  debit,
  invoice,
  receipt,
  statement,
  report,
  document,
  file,
  image,
  video,
  audio,
  text,
  chat,
  message,
  notification,
  alert,
  event,
  task,
  project,
  milestone,
  phase,
  stage,
  step,
  item,
  lineItem,
  bundle,
  package,
  kit,
  assembly,
  component,
  part,
  material,
  labor,
  expense,
  discount,
  tax,
  shipping,
  handling,
  fee,
  charge,
  adjustment,
  deposit,
  withdrawal,
  transfer,
  payment,
  refundPayment,
  commission,
  bonus,
  penalty,
  fine,
  interest,
  rebate,
  coupon,
  voucher,
  giftCard,
  loyaltyPoint,
  reward,
  referral,
  affiliate,
  advertisement,
  campaign,
  promotion,
  offer,
  deal,
  sale,
  purchase,
  order,
  quote,
  inquiry,
  request,
  response,
  feedback,
  review,
  rating,
  comment,
  post,
  article,
  blog,
  page,
  site,
  website,
  application,
  software,
  hardware,
  device,
  system,
  network,
  server,
  database,
  cloud,
  api,
  integration,
  plugin,
  module,
  library,
  framework,
  platform,
  tool,
  utility,
  script,
  code,
  data,
  information,
  content,
  media,
  asset,
  resource,
  documentType,
  reportType,
  transactionType,
  paymentType,
  messageType,
  notificationType,
  alertType,
  eventType,
  taskType,
  projectType,
  milestoneType,
  phaseType,
  stageType,
  stepType,
  itemType,
  lineItemType,
  bundleType,
  packageType,
  kitType,
  assemblyType,
  componentType,
  partType,
  materialType,
  laborType,
  expenseType,
  discountType,
  taxType,
  shippingType,
  handlingType,
  feeType,
  chargeType,
  adjustmentType,
  depositType,
  withdrawalType,
  transferType,
  paymentRefundType,
  commissionType,
  bonusType,
  penaltyType,
  fineType,
  interestType,
  rebateType,
  couponType,
  voucherType,
  giftCardType,
  loyaltyPointType,
  rewardType,
  referralType,
  affiliateType,
  advertisementType,
  campaignType,
  promotionType,
  offerType,
  dealType,
  saleType,
  purchaseType,
  orderType,
  quoteType,
  inquiryType,
  requestType,
  responseType,
  feedbackType,
  reviewType,
  ratingType,
  commentType,
  postType,
  articleType,
  blogType,
  pageType,
  siteType,
  websiteType,
  applicationType,
  softwareType,
  hardwareType,
  deviceType,
  systemType,
  networkType,
  serverType,
  databaseType,
  cloudType,
  apiType,
  integrationType,
  pluginType,
  moduleType,
  libraryType,
  frameworkType,
  platformType,
  toolType,
  utilityType,
  scriptType,
  codeType,
  dataType,
  informationType,
  contentType,
  mediaType,
  assetType,
  resourceType,
  unknown,
}
