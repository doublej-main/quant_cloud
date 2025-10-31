/**
 * @file bs_greeks.hpp
 * @brief Implementations of Black-Scholes Greeks (Delta & Gamma).
 *
 * @details This file provides functions for calculating Delta and Gamma 
 * using three different methods:
 * 1. Analytic (exact) formulas.
 * 2. Classical Forward Finite Differences (FFD).
 * 3. Complex-Step Differentiation (CSD).
 *
 * Exposes:
 * - analytic_delta:    Exact BS Delta.
 * - analytic_gamma:    Exact BS Gamma.
 * - ffd_delta:         Delta via FFD.
 * - ffd_gamma:         Gamma via FFD.
 * - csd_delta:         Delta via CSD (imaginary part).
 * - csd_gamma_real:    Gamma via CSD (real part).
 * - csd_gamma_45:      Gamma via CSD (45-degree).
 *
 * Intended as the implementation for the Greeks validation.
 */
#pragma once
#include "bs_templated_pricer.hpp"

// Analytic Greeks, i.e. benchmark "true" values (Delta)
inline double	analytic_delta(double S, double K, double r, double q, double sigma, double T)	{
	const double	F 		= S * std::exp((r -q) * T);
	const double	sigmaT 	= sigma * std::sqrt(std::max(T, 0.0));
		
	if (sigmaT == 0.0) return (F > K) ? std::exp(-q * T) : 0.0;

	double			ln_F_over_K;
	if (K > 0.0)	{
		const double	x = (F - K) / K;
		ln_F_over_K = (std::abs(x) <= 1e-12) ? std::log1p(x) : std::log(F / K);
	}	else	{
			ln_F_over_K = std::log(F / K);
	}

	const double	d1 = (ln_F_over_K + 0.5 * sigma * sigma * T) / sigmaT;
	return std::exp(-q * T) * Phi_real(d1);
}

// Analytic Greeks, i.e. benchmark "true" values (Gamma)
inline double	analytic_gamma(double S, double K, double r, double q, double sigma, double T)	{
	const double	F		= S * std::exp((r - q) * T);
	const double	sigmaT	= sigma * std::sqrt(std::max(T, 0.0));

	if (sigmaT == 0.0) return (0.0);

	double			ln_F_over_K;
	if (K > 0.0)	{
		const double	x = (F - K) / K;
		ln_F_over_K = (std::abs(x) <= 1e-12) ? std::log1p(x) : std::log(F / K);
	}	else	{
			ln_F_over_K = std::log(F / K);
	}

	const double	d1 = (ln_F_over_K + 0.5 * sigma * sigma * T) / sigmaT;

	// log(ϕ(d₁)) = -d₁²/2 - log(√(2π))
	static constexpr double	LOG_SQRT_2PI	= 0.91893853320467274178;
	const double log_phi_d1					= -0.5 * d1 * d1 - LOG_SQRT_2PI;
	const double phi_d1						= std::exp(log_phi_d1);

	return std::exp(-q * T) * phi_d1 / (S * sigmaT);
}

// Classical Forward Differences (Delta)
inline double	ffd_delta(double S, double K, double r, double q, double sigma, double T,  double h)	{
	double	C_S = bs_price_call(S, K, r, q, sigma, T);
	double	C_Sh = bs_price_call(S + h, K, r, q, sigma, T);
	
	return (C_Sh - C_S) / h;
}

// Classical Forward Differences (Gamma)
inline double	ffd_gamma(double S, double K, double r, double q, double sigma, double T, double h)	{
	double	C_S = bs_price_call(S, K, r, q, sigma, T);
	double	C_Sh = bs_price_call(S + h, K, r, q, sigma, T);
	double	C_S2h = bs_price_call(S + 2*h, K, r, q, sigma, T);
	
	return (C_S2h - 2.0 * C_Sh + C_S) / (h * h);
}

template<class T>
inline	std::complex<T> cplx(T val)	{
	return std::complex<T>(val, 0.0);
}

// Complex-Step differentiation (Delta)
inline double	csd_delta(double S, double K, double r, double q, double sigma, double T, double h)	{
	std::complex<double> S_h(S, h);
	std::complex<double> C_Sh = bs_price_call_t(
		S_h, cplx(K), cplx(r), cplx(q), cplx(sigma), cplx(T)
	);

	return C_Sh.imag() / h;
}

// Complex-Step differentiation (Gamma)
inline double	csd_gamma_real(double S, double K, double r, double q, double sigma, double T, double h)	{
	std::complex<double> S_h(S, h);
		std::complex<double> C_Sh = bs_price_call_t(
		S_h, cplx(K), cplx(r), cplx(q), cplx(sigma), cplx(T)
	);
	double	C_S = bs_price_call(S, K, r, q, sigma, T);

	return -2.0 * (C_Sh.real() - C_S) / (h * h);
}

// Complex-Step differentiation (Gamma 45)
inline double	csd_gamma_45(double S, double K, double r, double q, double sigma, double T, double h)	{
	static constexpr double INV_SQRT_2 = 0.70710678118654752440;
	const	std::complex<double> omega(INV_SQRT_2, INV_SQRT_2);
	std::complex<double> h_omega = h * omega;
	// C(S + hω)
	std::complex<double> C_plus = bs_price_call_t(
		cplx(S) + h_omega, cplx(K), cplx(r), cplx(q), cplx(sigma), cplx(T)
	);
	// C(S - hω)
	std::complex<double> C_minus = bs_price_call_t(
		cplx(S) - h_omega, cplx(K), cplx(r), cplx(q), cplx(sigma), cplx(T)
	);

	return (C_plus + C_minus).imag() / (h *h);
}
