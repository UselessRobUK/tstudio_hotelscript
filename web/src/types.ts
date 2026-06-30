export interface Room {
    id: number
    label: string
    price: number
    duration: number
    available: boolean
    myRoom?: boolean
    expires?: number
    state?: 'clean' | 'dirty' | string
}

export interface Tenant {
    identifier: string
    room: number
    expires: number
}

export interface Complaint {
    id: number
    identifier?: string
    room?: number
    roomId?: number
    category?: string
    message: string
    status: 'open' | 'resolved'
    created_at?: number
    resolved_at?: number
}

export interface Dashboard {
    hotel: string
    activeRooms: number
    tenants: Tenant[]
    revenue: number
    complaints: Complaint[]
    rooms?: Room[]
}

export type NuiMessage =
    | { action: 'openHotel'; data: { hotel: string; hotelName: string; rooms: Room[] } }
    | { action: 'openBoss'; data: { hotel: string; hotelName: string; dashboard: Dashboard } }
    | { action: 'openComplaints'; data: { hotel: string; hotelName: string; complaints: Complaint[] } }
    | { action: 'updateRooms'; data: { hotel: string; rooms: Room[] } }
    | { action: 'close' }
