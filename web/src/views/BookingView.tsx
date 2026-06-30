import { BedDouble, Clock, DollarSign, Building2 } from 'lucide-react'
import type { Room } from '../types'

function formatExpiry(ts: number) {
    const diff = ts - Math.floor(Date.now() / 1000)
    if (diff <= 0) return 'Expired'
    const h = Math.floor(diff / 3600)
    const m = Math.floor((diff % 3600) / 60)
    return h > 0 ? `${h}h ${m}m remaining` : `${m}m remaining`
}

export default function BookingView({ rooms }: { rooms: Room[] }) {
    const myRoom = rooms.find(r => r.myRoom)
    const floor  = myRoom ? Math.floor(myRoom.id / 100) : null

    return (
        <>
            <div className="page-head">
                <div>
                    <p className="page-title">My Booking</p>
                    <p className="page-sub">Your current active rental</p>
                </div>
            </div>

            {myRoom ? (
                <div className="booking-panel">
                    <p className="booking-panel-label"><BedDouble size={12} /> Active Rental</p>
                    <p className="booking-room-name">{myRoom.label ?? `Room ${myRoom.id}`}</p>
                    <div className="booking-detail-row">
                        <Building2 size={13} style={{ color: 'var(--text-3)' }} />
                        Floor {floor}
                    </div>
                    <div className="booking-detail-row">
                        <DollarSign size={13} style={{ color: 'var(--text-3)' }} />
                        ${myRoom.price} / {myRoom.duration}h stay
                    </div>
                    {myRoom.expires && (
                        <div className="booking-expiry">
                            <Clock size={14} />
                            {formatExpiry(myRoom.expires)}
                        </div>
                    )}
                </div>
            ) : (
                <div className="empty">
                    <div className="empty-icon"><BedDouble size={32} /></div>
                    <p>You don't have an active booking.</p>
                </div>
            )}
        </>
    )
}
