/**
 * @file bs_templated_cdf_dispatcher.hpp
 * @brief Templated dispatcher for the standard normal CDF (Φ).
 *
 * Provides specializations for `double` and `std::complex<double>`.
 * The complex specialization implements a first-order Taylor expansion
 * (complex-step approximation) of the CDF:
 * Φ(z_r + i*z_i) ≈ Φ(z_r) + i*z_i*φ(z_r)
 *
 * This is primarily intended for use with complex-step differentiation
 * to compute option Greeks.
 *
 * Exposes:
 * - Phi_t<T>(T z): Templated function prototype.
 * - Phi_t<double>(double z): Real-valued CDF (wraps Phi_real).
 * - Phi_t<std::complex<double>>(std::complex<double> z): Complex-step CDF approximation.
 *
 * @see bs_call_price.hpp (for real-valued Phi_real and phi)
 */
#pragma once
#include <complex>
#include "bs_call_price.hpp"

template<typename T>
T Phi_t(T z);

template<>
inline double Phi_t<double>(double z)	{
	return Phi_real(z);
}

template<>
inline std::complex<double> Phi_t<std::complex<double>>(std::complex<double>  z)	{
	double	z_r = z.real();
	double	z_i = z.imag();

	// Reuse the robust real implementations from bs_call_price.hpp
	double	cdf_real = Phi_real(z_r);
	double	pdf_real = phi(z_r);

	return std::complex<double>(cdf_real, z_i * pdf_real);
}