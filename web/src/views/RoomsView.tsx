import { useState } from 'react'
import { Search, CheckCircle2, Lock, Star, Clock, CreditCard, Banknote } from 'lucide-react'
import type { Room } from '../types'
import { nuiPost } from '../nui'

interface Props {
    rooms: Room[]
    payment: 'cash' | 'bank'
}

function formatExpiry(ts: number) {
    const diff = ts - Math.floor(Date.now() / 1000)
    if (diff <= 0) return 'Expired'
    const h = Math.floor(diff / 3600)
    const m = Math.floor((diff % 3600) / 60)
    return h > 0 ? `${h}h ${m}m remaining` : `${m}m remaining`
}

export default function RoomsView({ rooms, payment }: Props) {
    const [query,       setQuery]       = useState('')
    const [bookRoom,    setBookRoom]    = useState<Room | null>(null)
    const [payMethod,   setPayMethod]   = useState<'cash' | 'bank'>(payment)
    const [confirming,  setConfirming]  = useState(false)

    const filtered = rooms.filter(r =>
        (r.label ?? `Room ${r.id}`).toLowerCase().includes(query.toLowerCase())
    )

    async function confirmRent() {
        if (!bookRoom) return
        setConfirming(true)
        await nuiPost('rentRoom', { roomId: bookRoom.id, payment: payMethod })
        setConfirming(false)
        setBookRoom(null)
    }

    return (
        <>
            <div className="page-head">
                <div>
                    <p className="page-title">Rooms</p>
                    <p className="page-sub">{rooms.filter(r => r.available).length} available · {rooms.filter(r => !r.available).length} occupied</p>
                </div>
            </div>

            <div className="search-wrap">
                <Search size={14} className="search-icon" />
                <input
                    className="search-input"
                    placeholder="Search rooms…"
                    value={query}
                    onChange={e => setQuery(e.target.value)}
                />
            </div>

            {filtered.length === 0 ? (
                <div className="empty">
                    <div className="empty-icon"><Search size={28} /></div>
                    <p>No rooms match your search.</p>
                </div>
            ) : (
                <div className="rooms-grid">
                    {filtered.map(room => (
                        <RoomCard key={room.id} room={room} onBook={setBookRoom} />
                    ))}
                </div>
            )}

            {bookRoom && (
                <div className="modal-backdrop" onClick={e => { if (e.target === e.currentTarget) setBookRoom(null) }}>
                    <div className="modal">
                        <p className="modal-title"><CheckCircle2 size={16} /> Confirm Booking</p>
                        <div className="modal-room-box">
                            <p className="name">{bookRoom.label}</p>
                            <p className="price">${bookRoom.price}</p>
                            <p className="meta">{bookRoom.duration}-hour stay · non-refundable</p>
                        </div>
                        <div className="pay-row">
                            <button className={`pay-opt${payMethod === 'cash' ? ' active' : ''}`} onClick={() => setPayMethod('cash')}>
                                <Banknote size={14} /> Cash
                            </button>
                            <button className={`pay-opt${payMethod === 'bank' ? ' active' : ''}`} onClick={() => setPayMethod('bank')}>
                                <CreditCard size={14} /> Bank Card
                            </button>
                        </div>
                        <div className="modal-actions">
                            <button className="btn btn-pink" onClick={confirmRent} disabled={confirming}>
                                {confirming ? 'Processing…' : 'Book Now'}
                            </button>
                            <button className="btn btn-ghost" onClick={() => setBookRoom(null)}>Cancel</button>
                        </div>
                    </div>
                </div>
            )}
        </>
    )
}

function RoomCard({ room, onBook }: { room: Room; onBook: (r: Room) => void }) {
    const mine     = !!room.myRoom
    const occupied = !room.available && !mine
    const floor    = Math.floor(room.id / 100)
    const status   = mine ? 'mine' : occupied ? 'occupied' : 'available'

    return (
        <div className={`room-card ${status}`}>
            <div className="room-card-top">
                <div>
                    <p className="room-name">{room.label ?? `Room ${room.id}`}</p>
                    <p className="room-floor">Floor {floor}</p>
                </div>
                {mine     && <span className="badge badge-pink"><Star size={8} /> Yours</span>}
                {occupied && !mine && <span className="badge badge-err"><Lock size={8} /> Occupied</span>}
                {!occupied && !mine && <span className="badge badge-ok"><CheckCircle2 size={8} /> Free</span>}
            </div>

            <div>
                <span className="room-price">${room.price}</span>
                <span className="room-price-per"> / {room.duration}h</span>
            </div>

            {mine && room.expires && (
                <p className="room-expiry"><Clock size={11} />{formatExpiry(room.expires)}</p>
            )}

            {room.state && room.state !== 'clean' && (
                <span className="badge badge-warn" style={{ alignSelf: 'flex-start' }}>{room.state}</span>
            )}

            {!occupied && !mine && (
                <button className="book-btn" onClick={() => onBook(room)}>Book Room</button>
            )}
        </div>
    )
}
