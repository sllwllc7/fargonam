export type MeUser = {
  id: number;
  phone: string | null;
  full_name: string | null;
  role: "buyer" | "seller" | "admin";
  avatar_url: string | null;
  is_active: boolean;
  created_at: string;
};

export type ProductStatus = "draft" | "pending" | "approved" | "rejected";

export type VariantOut = {
  id: number;
  product_id: number;
  sku: string;
  variant_name: string;
  price: number;
  old_price: number | null;
  stock: number;
  attributes: Record<string, unknown>;
  image_url: string | null;
  is_active: boolean;
  sort_order: number;
};

export type ProductPendingEdit = {
  name?: string;
  brand?: string | null;
  description?: string | null;
  category_id?: number | null;
  image_url?: string | null;
  thumb_url?: string | null;
};

export type ProductOut = {
  id: number;
  shop_id: number;
  category_id: number | null;
  name: string;
  slug: string | null;
  brand: string | null;
  description: string | null;
  image_url: string | null;
  thumb_url: string | null;
  is_active: boolean;
  created_at: string;
  shop_name: string | null;
  seller_phone: string | null;
  variants: VariantOut[];
  min_price: string | null;
  max_price: string | null;
  total_stock: number;
  price: string | null;
  stock: number | null;
  status: ProductStatus;
  rejected_reason: string | null;
  pending_edit: ProductPendingEdit | null;
  submitted_at: string | null;
};

export type Page<T> = {
  items: T[];
  total: number;
  limit: number;
  offset: number;
};

export type CategoryOut = {
  id: number;
  name: string;
  slug: string;
  parent_id: number | null;
  icon: string | null;
  color: string | null;
  sort_order: number;
  product_count: number;
  image_url: string | null;
  thumb_url: string | null;
};
