import { Banknote, CreditCard } from 'lucide-react'

interface Props {
    payment: 'cash' | 'bank'
    onPaymentChange: (v: 'cash' | 'bank') => void
}

export default function SettingsView({ payment, onPaymentChange }: Props) {
    return (
        <>
            <div className="page-head">
                <div>
                    <p className="page-title">Settings</p>
                    <p className="page-sub">Your preferences</p>
                </div>
            </div>

            <div className="settings-section">
                <div className="field-group">
                    <label className="field-label">Default Payment Method</label>
                    <div className="pay-row">
                        <button
                            className={`pay-opt${payment === 'cash' ? ' active' : ''}`}
                            onClick={() => onPaymentChange('cash')}
                        >
                            <Banknote size={14} /> Cash
                        </button>
                        <button
                            className={`pay-opt${payment === 'bank' ? ' active' : ''}`}
                            onClick={() => onPaymentChange('bank')}
                        >
                            <CreditCard size={14} /> Bank Card
                        </button>
                    </div>
                </div>
            </div>
        </>
    )
}
